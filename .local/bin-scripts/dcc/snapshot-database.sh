#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
CONTAINER=data-management-db-1
DOCKER=(docker --host unix:///var/run/docker.sock)
DB_USER=luay
usage() { echo "Usage: dcc db-snapshot DATABASE NEW_DIRECTORY [--user ROLE]"; }
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
[[ $# -ge 2 ]] || { usage >&2; exit 1; }
DATABASE=$1
OUTPUT=$2
shift 2
while (( $# )); do
  case $1 in
    --user) [[ $# -ge 2 ]] || exit 1; DB_USER=$2; shift 2 ;;
    *) usage >&2; exit 1 ;;
  esac
done
[[ -n $DATABASE && $DATABASE != *$'\n'* && ! -e $OUTPUT ]] || { echo 'Use a database name without newlines and a new output directory.' >&2; exit 1; }
mkdir -p -- "$(dirname -- "$OUTPUT")"
OUTPUT=$(realpath -m -- "$OUTPUT")
WORK=$(mktemp -d "$(dirname -- "$OUTPUT")/.dcc-snapshot.XXXXXXXX")
cleanup() { local status=$?; trap - EXIT; [[ ! -d $WORK ]] || rm -rf -- "$WORK"; exit "$status"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
psql_source() {
  "${DOCKER[@]}" exec -i --env "PGDATABASE=$DATABASE" --env PGHOST=/var/run/postgresql --env PGPORT=5432 "$CONTAINER" \
    psql -X -w -qAt -v ON_ERROR_STOP=1 -U "$DB_USER"
}
printf '%s\n' "$DATABASE" > "$WORK/database-name"
psql_source > "$WORK/create.sql" <<'SQL'
SELECT format('CREATE DATABASE %I TEMPLATE template0 OWNER %I ENCODING %L LC_COLLATE %L LC_CTYPE %L %s TABLESPACE %I;',
 '__DCC_RESTORE_DATABASE__', pg_get_userbyid(datdba), pg_encoding_to_char(encoding), datcollate, datctype,
 CASE datlocprovider WHEN 'c' THEN 'LOCALE_PROVIDER=libc'
 WHEN 'i' THEN format('LOCALE_PROVIDER=icu ICU_LOCALE=%L', daticulocale)
 ELSE 'UNSUPPORTED_LOCALE_PROVIDER' END,
 (SELECT spcname FROM pg_tablespace WHERE oid=dattablespace))
FROM pg_database WHERE datname=current_database();
SQL
psql_source > "$WORK/properties.sql" <<'SQL'
SELECT format('ALTER DATABASE %I CONNECTION LIMIT %s;', '__DCC_RESTORE_DATABASE__', datconnlimit)
FROM pg_database WHERE datname=current_database();
SELECT format('COMMENT ON DATABASE %I IS %L;', '__DCC_RESTORE_DATABASE__', shobj_description(oid,'pg_database'))
FROM pg_database WHERE datname=current_database();
SELECT format('REVOKE ALL ON DATABASE %I FROM PUBLIC; REVOKE ALL ON DATABASE %I FROM %I;',
 '__DCC_RESTORE_DATABASE__', '__DCC_RESTORE_DATABASE__', pg_get_userbyid(datdba))
FROM pg_database WHERE datname=current_database();
SELECT format('GRANT %s ON DATABASE %I TO %s%s;', acl.privilege_type, '__DCC_RESTORE_DATABASE__',
 CASE WHEN acl.grantee=0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(acl.grantee)) END,
 CASE WHEN acl.is_grantable THEN ' WITH GRANT OPTION' ELSE '' END)
FROM pg_database d CROSS JOIN LATERAL aclexplode(coalesce(d.datacl,acldefault('d',d.datdba))) acl
WHERE d.datname=current_database();
SELECT CASE WHEN s.setrole=0
 THEN format('ALTER DATABASE %I SET %I TO %L;', '__DCC_RESTORE_DATABASE__', split_part(v,'=',1), substr(v,strpos(v,'=')+1))
 ELSE format('ALTER ROLE %I IN DATABASE %I SET %I TO %L;', pg_get_userbyid(s.setrole), '__DCC_RESTORE_DATABASE__', split_part(v,'=',1), substr(v,strpos(v,'=')+1)) END
FROM pg_db_role_setting s CROSS JOIN LATERAL unnest(s.setconfig) v
WHERE s.setdatabase=(SELECT oid FROM pg_database WHERE datname=current_database());
SQL
psql_source > "$WORK/allow-connections" <<'SQL'
SELECT datallowconn FROM pg_database WHERE datname=current_database();
SQL
"${DOCKER[@]}" exec --env "PGDATABASE=$DATABASE" --env PGHOST=/var/run/postgresql --env PGPORT=5432 "$CONTAINER" \
  pg_dump --username="$DB_USER" --no-password --format=custom --create --lock-wait-timeout=15s > "$WORK/database.dump"
(
  cd -- "$WORK"
  sha256sum database.dump database-name create.sql properties.sql allow-connections > checksums.sha256
)
mv -T -- "$WORK" "$OUTPUT"
printf 'Snapshot saved: %s\n' "$OUTPUT"
