#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
CONTAINER=data-management-db-1
DOCKER=(docker --host unix:///var/run/docker.sock)
DB_USER=luay
TARGET=''
ASSUME_YES=0
usage() { echo 'Usage: dcc db-restore SNAPSHOT_DIRECTORY [--database TARGET] [--user ROLE] [--yes]'; }
if [[ ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
[[ $# -ge 1 ]] || { usage >&2; exit 1; }
SNAPSHOT=$(realpath -e -- "$1")
shift
while (( $# )); do
  case $1 in
    --database) [[ $# -ge 2 ]] || exit 1; TARGET=$2; shift 2 ;;
    --user) [[ $# -ge 2 ]] || exit 1; DB_USER=$2; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    *) usage >&2; exit 1 ;;
  esac
done
[[ -n $TARGET ]] || IFS= read -r TARGET < "$SNAPSHOT/database-name"
[[ -n $TARGET && $TARGET != *$'\n'* && ${#TARGET} -le 63 ]] || { echo 'Invalid target database name.' >&2; exit 1; }
case $TARGET in postgres|template0|template1) echo 'System database targets are refused.' >&2; exit 1 ;; esac
exec 9< "$SNAPSHOT/database.dump"
flock -n 9 || { echo 'This snapshot is already being restored.' >&2; exit 1; }
(
  cd -- "$SNAPSHOT"
  for file in database.dump database-name create.sql properties.sql allow-connections; do
    expected=$(awk -v name="$file" '$2 == name {print $1}' checksums.sha256)
    actual=$(sha256sum -- "$file")
    [[ $expected =~ ^[0-9a-f]{64}$ && ${actual%% *} == "$expected" ]] || { echo "Checksum mismatch: $file" >&2; exit 1; }
  done
)
if (( ! ASSUME_YES )); then
  printf 'Stop applications using %s. Type the database name to replace it: ' "$TARGET" > /dev/tty
  IFS= read -r answer < /dev/tty
  [[ $answer == "$TARGET" ]] || { echo 'Restore cancelled.' >&2; exit 1; }
fi
TOKEN=$(date +%Y%m%d%H%M%S)_$$_${RANDOM}
STAGE=dcc_restore_$TOKEN
PREVIOUS=dcc_previous_$TOKEN
APP=dcc_restore_$TOKEN
MADE_STAGE=0
BLOCKED_TARGET=0
SWAPPED=0
ORIGINAL_ALLOW=''
psql_admin() {
  "${DOCKER[@]}" exec -i --env PGDATABASE=postgres --env PGHOST=/var/run/postgresql --env PGPORT=5432 --env "PGAPPNAME=$APP" "$CONTAINER" \
    psql -X -w -qAt -v ON_ERROR_STOP=1 -U "$DB_USER" \
    -v "target=$TARGET" -v "stage=$STAGE" -v "previous=$PREVIOUS" -v "app=$APP" "$@"
}
cleanup() {
  local status=$?
  trap - EXIT INT TERM HUP
  if (( ! SWAPPED && MADE_STAGE )); then
    psql_admin <<'SQL' || true
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE application_name=:'app' AND datname=:'stage';
SQL
    printf 'Restore did not confirm a completed swap. Inspect staging %s and rollback %s before retrying.\n' "$STAGE" "$PREVIOUS" >&2
  fi
  if (( BLOCKED_TARGET && ! SWAPPED )); then
    if [[ $ORIGINAL_ALLOW == t ]]; then
      psql_admin <<'SQL' || true
ALTER DATABASE :"target" ALLOW_CONNECTIONS true;
SQL
    fi
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
superuser=$(psql_admin <<'SQL'
SELECT rolsuper FROM pg_roles WHERE rolname=current_user;
SQL
)
[[ $superuser == t ]] || { echo 'A local superuser is required to preserve ownership and event triggers.' >&2; exit 1; }
ORIGINAL_ALLOW=$(psql_admin <<'SQL'
SELECT CASE WHEN datistemplate THEN 'template' ELSE datallowconn::text END
FROM pg_database WHERE datname=:'target';
SQL
)
[[ $ORIGINAL_ALLOW != template ]] || { echo 'Template database targets are refused.' >&2; exit 1; }
case $ORIGINAL_ALLOW in true) ORIGINAL_ALLOW=t ;; false) ORIGINAL_ALLOW=f ;; esac
active=$(psql_admin <<'SQL'
SELECT count(*) FROM pg_stat_activity WHERE datname=:'target';
SQL
)
[[ $active == 0 ]] || { echo 'Target has active connections. Stop backend/pgAdmin sessions first.' >&2; exit 1; }
sed "s/__DCC_RESTORE_DATABASE__/$STAGE/g" "$SNAPSHOT/create.sql" | psql_admin
MADE_STAGE=1
"${DOCKER[@]}" exec -i --env "PGDATABASE=$STAGE" --env PGHOST=/var/run/postgresql --env PGPORT=5432 --env "PGAPPNAME=$APP" "$CONTAINER" \
  pg_restore --username="$DB_USER" --no-password --exit-on-error --single-transaction < "$SNAPSHOT/database.dump"
sed "s/__DCC_RESTORE_DATABASE__/$STAGE/g" "$SNAPSHOT/properties.sql" | psql_admin --single-transaction
if [[ -n $ORIGINAL_ALLOW ]]; then
  BLOCKED_TARGET=1
  psql_admin <<'SQL'
ALTER DATABASE :"target" ALLOW_CONNECTIONS false;
SQL
  active=$(psql_admin <<'SQL'
SELECT count(*) FROM pg_stat_activity WHERE datname=:'target';
SQL
)
  [[ $active == 0 ]] || { echo 'A target connection appeared; cancelling the swap.' >&2; exit 1; }
fi
psql_admin <<'SQL'
ALTER DATABASE :"stage" ALLOW_CONNECTIONS false;
SQL
IFS= read -r RESTORED_ALLOW < "$SNAPSHOT/allow-connections"
[[ $RESTORED_ALLOW == t || $RESTORED_ALLOW == f ]] || { echo 'Invalid connection-availability metadata.' >&2; exit 1; }
{
  echo 'BEGIN;'
  if [[ -n $ORIGINAL_ALLOW ]]; then echo 'ALTER DATABASE :"target" RENAME TO :"previous";'; fi
  echo 'ALTER DATABASE :"stage" RENAME TO :"target";'
  if [[ $RESTORED_ALLOW == t ]]; then echo 'ALTER DATABASE :"target" ALLOW_CONNECTIONS true;'; fi
  echo 'COMMIT;'
} | psql_admin
SWAPPED=1
printf 'Restored database: %s\n' "$TARGET"
if [[ -n $ORIGINAL_ALLOW ]]; then printf 'Previous database retained as %s (connections disabled).\n' "$PREVIOUS"; fi
