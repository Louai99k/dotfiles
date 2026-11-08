#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

BACKUP_DIR="/home/luay/me/childcare/_childcare/database-docker/pgadmin/storage/admin_admin.com"
CONTAINER="data-management-db-1"
DOCKER=(docker --host unix:///var/run/docker.sock)
ARCHIVE=''
ASSUME_YES=0
CONTAINER_TMP=''
RESTORE_STARTED=0
RESTORE_APP="dcc_restore_master_db_$(date '+%s')_$$"

usage() {
  printf 'Usage: %s [-y] [-f /path/to/master_dump_YYYYMMDDHHMMSS]\n' "${0##*/}"
  printf 'Without -f, restore the newest archive in %s.\n' "$BACKUP_DIR"
  printf '  -y  Explicitly confirm replacement of local master_db without a terminal prompt.\n'
}

while getopts ':f:hy' option; do
  case "$option" in
    f) ARCHIVE="$OPTARG" ;;
    y) ASSUME_YES=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
shift "$((OPTIND - 1))"
if [[ $# -ne 0 ]]; then
  usage >&2
  exit 1
fi

for program in docker sha256sum flock realpath tee; do
  if ! command -v "$program" > /dev/null; then
    printf 'ERROR: required program is missing: %s\n' "$program" >&2
    exit 1
  fi
done

if [[ "$ASSUME_YES" -eq 0 ]] && ! ( : < /dev/tty ) 2>/dev/null; then
  printf 'ERROR: no interactive terminal. To explicitly authorize replacing local master_db, run: dcc master-db-restore -y\n' >&2
  exit 1
fi

if [[ -z "$ARCHIVE" ]]; then
  shopt -s nullglob
  for candidate in "$BACKUP_DIR"/master_dump_*; do
    name="${candidate##*/}"
    if [[ -f "$candidate" && "$name" =~ ^master_dump_[0-9]{14}$ ]]; then
      if [[ -z "$ARCHIVE" || "$name" > "${ARCHIVE##*/}" ]]; then
        ARCHIVE="$candidate"
      fi
    fi
  done
fi

if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" || ! -r "$ARCHIVE" || ! -s "$ARCHIVE" ]]; then
  printf 'ERROR: no readable, nonempty backup found. Download the new full backup first.\n' >&2
  exit 1
fi
ARCHIVE="$(realpath -- "$ARCHIVE")"
BASENAME="${ARCHIVE##*/}"
ARCHIVE_DIR="${ARCHIVE%/*}"
if [[ ! "$BASENAME" =~ ^master_dump_[0-9]{14}$ ]]; then
  printf 'ERROR: expected an archive named master_dump_YYYYMMDDHHMMSS.\n' >&2
  exit 1
fi
for suffix in .roles.sql .sha256; do
  if [[ ! -r "$ARCHIVE$suffix" || ! -s "$ARCHIVE$suffix" ]]; then
    printf 'ERROR: incomplete backup bundle; missing %s%s. Re-run the downloader.\n' "$BASENAME" "$suffix" >&2
    exit 1
  fi
done

actual_checksums="$(cd "$ARCHIVE_DIR" && sha256sum -- "$BASENAME" "$BASENAME.roles.sql")"
expected_checksums="$(cat -- "$ARCHIVE.sha256")"
if [[ "$actual_checksums" != "$expected_checksums" ]]; then
  printf 'ERROR: backup checksum mismatch. Download the bundle again before restoring.\n' >&2
  exit 1
fi

exec {restore_lock}> "$BACKUP_DIR/.restore_master_db.lock"
if ! flock -n "$restore_lock"; then
  printf 'ERROR: another master_db restore is running.\n' >&2
  exit 1
fi

LOG_FILE="$BACKUP_DIR/restore_master_db_$(date '+%Y%m%d%H%M%S').log"
exec > >(tee -a "$LOG_FILE") 2>&1

cleanup() {
  status=$?
  trap - EXIT
  trap '' INT TERM HUP
  if [[ "$status" -ne 0 && "$RESTORE_STARTED" -eq 1 ]]; then
    "${DOCKER[@]}" exec -i "$CONTAINER" psql -X -q -U luay -d master_db \
      --set=ON_ERROR_STOP=1 --set=restore_app="$RESTORE_APP" <<'SQL' || true
SELECT pg_terminate_backend(pid, 10000)
FROM pg_stat_activity
WHERE datname = 'master_db' AND usename = 'luay'
  AND application_name = :'restore_app' AND pid <> pg_backend_pid();
SQL
  fi
  if [[ "$CONTAINER_TMP" =~ ^/tmp/dcc-restore-master-db\.[[:alnum:]]{8}$ ]]; then
    "${DOCKER[@]}" exec "$CONTAINER" rm -rf -- "$CONTAINER_TMP" || true
  fi
  if [[ "$status" -ne 0 ]]; then
    printf 'Restore failed or was interrupted. SQL errors roll back the replacement; check the log before retrying.\n'
    printf 'Log: %s\n' "$LOG_FILE"
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

"${DOCKER[@]}" exec -i "$CONTAINER" psql -X -U luay -d master_db \
  --set=ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF current_database() <> 'master_db' OR current_user <> 'luay' THEN
    RAISE EXCEPTION 'Unexpected database or administrative role';
  END IF;
  IF current_setting('server_version_num')::integer / 10000 <> 16 THEN
    RAISE EXCEPTION 'This restore script expects PostgreSQL 16';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'luay' AND rolsuper) THEN
    RAISE EXCEPTION 'Local luay must be a superuser to restore event triggers';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rls' AND NOT rolsuper AND NOT rolbypassrls)
     OR NOT has_database_privilege('rls', current_database(), 'CREATE') THEN
    RAISE EXCEPTION 'Local rls must exist without superuser/BYPASSRLS and be able to create schemas';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid()) THEN
    RAISE EXCEPTION 'Stop the app and disconnect pgAdmin sessions from master_db before restoring';
  END IF;
END;
$$;
SQL

CONTAINER_TMP="$("${DOCKER[@]}" exec "$CONTAINER" mktemp -d /tmp/dcc-restore-master-db.XXXXXXXX)"
"${DOCKER[@]}" exec -i "$CONTAINER" bash -c 'umask 077; cat > "$1/archive.dump"' bash "$CONTAINER_TMP" < "$ARCHIVE"

printf 'Preparing SQL files only; the database has not been changed.\n'
"${DOCKER[@]}" exec -i "$CONTAINER" bash -s -- "$CONTAINER_TMP" <<'PREPARE'
set -Eeuo pipefail
umask 077
cd "$1"
pg_restore --list archive.dump > archive.list
if ! awk '/^[0-9]+;.* EVENT TRIGGER - soft_delete_event_trigger[[:space:]]/ { found=1 } END { exit !found }' archive.list; then
  printf 'ERROR: this archive lacks soft_delete_event_trigger. Use a new complete production backup.\n' >&2
  exit 1
fi
awk '
  /^[0-9]+;.* EVENT TRIGGER / { print > "events.list"; next }
  /^[0-9]+;.* SCHEMA - public[[:space:]]/ { next }
  { print > "normal.list" }
' archive.list
pg_restore --no-owner --no-privileges --use-list=normal.list --verbose --file=normal.sql archive.dump
pg_restore --no-owner --no-privileges --use-list=events.list --verbose --file=events.sql archive.dump
PREPARE

printf '\nArchive: %s\nTarget: local %s / master_db\n' "$ARCHIVE" "$CONTAINER"
printf 'This replaces the application schemas and data. Local roles are kept.\n'
if [[ "$ASSUME_YES" -eq 1 ]]; then
  printf 'Replacement explicitly confirmed with -y.\n'
else
  printf 'Type master_db to continue: '
  if ! read -r confirmation < /dev/tty || [[ "$confirmation" != 'master_db' ]]; then
    printf '\nRestore cancelled; the database was not changed.\n'
    exit 1
  fi
fi

RESTORE_STARTED=1
"${DOCKER[@]}" exec -i "$CONTAINER" bash -s -- "$CONTAINER_TMP" "$RESTORE_APP" <<'RESTORE'
set -Eeuo pipefail
umask 077
cd "$1"
export PGAPPNAME="$2"

cat > before.sql <<'SQL'
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = 0;
DO $$
DECLARE item record;
BEGIN
  IF current_database() <> 'master_db' THEN
    RAISE EXCEPTION 'Refusing to replace any database other than master_db';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid()) THEN
    RAISE EXCEPTION 'Another session connected to master_db; disconnect it before restoring';
  END IF;
  FOR item IN SELECT evtname FROM pg_event_trigger LOOP
    EXECUTE format('DROP EVENT TRIGGER %I', item.evtname);
  END LOOP;
  FOR item IN SELECT nspname FROM pg_namespace
              WHERE nspname <> 'information_schema' AND nspname !~ '^pg_' LOOP
    EXECUTE format('DROP SCHEMA %I CASCADE', item.nspname);
  END LOOP;
  PERFORM lo_unlink(oid) FROM pg_largeobject_metadata;
END;
$$;
CREATE SCHEMA public AUTHORIZATION rls;
SET LOCAL ROLE rls;
SQL

cat > owners.sql <<'SQL'
RESET ROLE;
ALTER FUNCTION public.soft_delete() OWNER TO luay;
ALTER FUNCTION public.apply_soft_delete_options() OWNER TO luay;
SQL

cat > after.sql <<'SQL'
DO $$
DECLARE bad_tables text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_event_trigger e JOIN pg_proc p ON p.oid = e.evtfoid
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE e.evtname = 'soft_delete_event_trigger'
      AND e.evtevent = 'ddl_command_end' AND e.evtenabled IN ('O','A')
      AND e.evttags = ARRAY['CREATE TABLE']::text[]
      AND pg_get_userbyid(e.evtowner) = 'luay'
      AND n.nspname = 'public' AND p.proname = 'apply_soft_delete_options'
  ) THEN
    RAISE EXCEPTION 'The expected soft-delete event trigger was not restored enabled under luay';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname IN ('soft_delete','apply_soft_delete_options')
      AND p.pronargs = 0 AND (pg_get_userbyid(p.proowner) <> 'luay' OR NOT p.prosecdef)
  ) THEN
    RAISE EXCEPTION 'Soft-delete functions must be SECURITY DEFINER and owned by luay';
  END IF;
  IF to_regclass('public.cc_students_list') IS NULL
     OR to_regclass('public.cc_guardians_list') IS NULL
     OR to_regclass('public.cc_teachers_list') IS NULL THEN
    RAISE EXCEPTION 'An expected application view is missing';
  END IF;
  SELECT string_agg(format('%I.%I',n.nspname,c.relname), ', ' ORDER BY n.nspname,c.relname)
    INTO bad_tables
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r','p') AND n.nspname <> 'information_schema' AND n.nspname !~ '^pg_'
      AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'deleted_at' AND NOT a.attisdropped)
      AND (
        NOT c.relrowsecurity OR NOT c.relforcerowsecurity
        OR pg_get_userbyid(c.relowner) <> 'rls'
        OR NOT EXISTS (
          SELECT 1 FROM pg_trigger t JOIN pg_proc p ON p.oid = t.tgfoid
          JOIN pg_namespace pn ON pn.oid = p.pronamespace
          WHERE t.tgrelid = c.oid AND NOT t.tgisinternal AND t.tgenabled IN ('O','A')
            AND t.tgtype = 11 AND pn.nspname = 'public' AND p.proname = 'soft_delete'
        )
        OR NOT EXISTS (
          SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polname = 'soft_delete_policy'
            AND p.polcmd = '*' AND p.polpermissive AND p.polroles = ARRAY[0::oid]
            AND pg_get_expr(p.polqual,p.polrelid) = '(deleted_at IS NULL)'
            AND pg_get_expr(p.polwithcheck,p.polrelid) = 'true'
        )
      );
  IF bad_tables IS NOT NULL THEN
    RAISE EXCEPTION 'Soft-delete protection or local ownership is incomplete on: %', bad_tables;
  END IF;
END;
$$;
SQL

psql -X -U luay -d master_db --set=ON_ERROR_STOP=1 --single-transaction \
  --file=before.sql --file=normal.sql --file=owners.sql --file=events.sql --file=after.sql
RESTORE

printf '\nRestore committed successfully.\n'
printf 'Ordinary objects use local rls; the privileged functions and event triggers use luay.\n'
printf 'No local role definitions were changed. Log: %s\n' "$LOG_FILE"
