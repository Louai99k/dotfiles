# dcc master-db-restore

Replaces the contents of LOCAL master_db with a downloaded production backup, after explicit confirmation. Script: restore-master-db.sh. All database changes happen together in one transaction. The downloaded .roles.sql file is checked but NEVER executed, so local roles are kept.

Restore the newest downloaded dump, or a specific one:

    dcc master-db-restore
    dcc master-db-restore -f /path/to/master_dump_YYYYMMDDHHMMSS

Replace without the terminal prompt:

    dcc master-db-restore -y

Options:

    -f FILE     Archive to restore. Default: newest in the download folder.
    -y          Explicitly confirm replacing local master_db without a prompt. Other checks still run.
    -h, --help  Show this help. Nothing else runs, even with other options.

Stop the app and disconnect pgAdmin first. Any other connection to master_db stops the restore, including an idle pgAdmin connection. The script never terminates those sessions.

Requires docker, sha256sum, flock, realpath and tee on the host, and the data-management-db-1 container running PostgreSQL 16. Without -y it also needs a terminal, and it fails before any preparation if there is none. Having no terminal never implies consent.

## Local-only targeting

The Docker socket is explicit (unix:///var/run/docker.sock), so a remote DOCKER_HOST or context is not used. PostgreSQL connections use the Unix socket inside the fixed local container, as role luay, never a production hostname or the production credentials from the server backup scripts. Files are created private (umask 077) because temporary SQL contains the production-copy row data.

## Choosing and checking the backup

The folder is the one dcc master-db downloads into. This script only selects files already on disk: /home/luay/me/childcare/_childcare/database-docker/pgadmin/storage/admin_admin.com

Automatic selection accepts only names matching master_dump_ plus exactly 14 digits, which excludes sidecars and logs. Newest means the filename timestamp, not modification time. If the newest bundle is incomplete, it stops and does not fall back to an older backup. A file given with -f must match the same name format.

The backup publisher uploads three matching files. Both sidecars must sit beside the archive: the roles file is part of bundle integrity, and the .sha256 file is published last as the completion marker. Fresh SHA-256 digests of the archive and roles file are compared with the whole expected two-line manifest, instead of letting sha256sum follow filenames from the manifest, which also rejects extra entries. These hashes detect changed or incomplete downloads. They are checksums, not signatures proving origin.

The archive must contain soft_delete_event_trigger, which rejects old public-only backups before any replacement begins.

## Order of work

1. Takes an advisory lock on .restore_master_db.lock in the download folder, so a second restore stops. The lock lasts while the process holds it, so a leftover file is not a stale lock. It coordinates restore scripts only, not Strapi or pgAdmin connections.
2. Starts a log, restore_master_db_YYYYMMDDHHMMSS.log, in the same folder. tee runs asynchronously, so a later tee failure is not detected.
3. Preflight, which changes nothing: database is master_db and user is luay; server is PostgreSQL 16; luay is a superuser, needed for event triggers rather than for the app; rls exists with no superuser or BYPASSRLS and has CREATE on the database, so it can recreate schemas; no other connections. Role definitions are checked without importing the roles sidecar.
4. Streams the archive into a private /tmp/dcc-restore-master-db.XXXXXXXX directory in the container, owned by the container's normal user. The host folder is not assumed to be mounted there.
5. Prepares SQL files only, with no database connection. Event triggers and their comments are split out to be restored after tables and data. The public schema's creation entry is dropped because it is recreated explicitly, since pg_dump can omit it. --no-owner and --no-privileges omit owner changes, GRANT/REVOKE and default ACLs, but keep table data, RLS policies, triggers and function definitions. Roles referenced by those definitions must exist, or the restore errors.
6. Shows archive and target, then asks you to type master_db, read from the terminal rather than stdin. Cancelling exits nonzero with the database unchanged.
7. Runs the replacement below, then removes the temporary container files. The downloaded backup and its sidecars are kept.

## The replacement transaction

One psql connection runs five SQL files in order with --single-transaction and ON_ERROR_STOP. Nothing commits until the end, and the first error rolls everything back.

before.sql sets lock_timeout to 5s, so a connection cannot make schema removal wait forever, and statement_timeout to 0, so a large restore can take as long as it needs. Dump SQL has its own session settings, so the lock timeout is not guaranteed for every later statement. It rechecks for new connections and refuses if someone connected since preflight. It drops existing event triggers first so old DDL hooks cannot interfere, drops ALL non-system schemas with CASCADE (not just public), and unlinks large objects to avoid OID collisions and leftovers. The database and its cluster-wide roles are not dropped. It then recreates public owned by rls and switches to role rls with SET LOCAL ROLE, so ordinary restored objects belong to rls.

normal.sql loads the archive's ordinary objects and data.

owners.sql returns to luay and gives public.soft_delete() and public.apply_soft_delete_options() to luay. They are SECURITY DEFINER, so their owner is the privilege context when invoked. This reproduces the manual pgAdmin owner fix. A missing function aborts the restore.

events.sql restores the event triggers as luay, last, so incoming DDL hooks do not fire during the rebuild.

after.sql runs final checks before COMMIT. Any failure rolls back the whole restore:

    soft_delete_event_trigger is enabled (O or A) on ddl_command_end for exactly CREATE TABLE, owned by luay, calling public.apply_soft_delete_options.
    Both soft-delete functions are SECURITY DEFINER and owned by luay.
    Views cc_students_list, cc_guardians_list and cc_teachers_list exist.
    Every non-system table with a live deleted_at column has ENABLE and FORCE ROW LEVEL SECURITY and is owned by rls.
    Each of those tables has an enabled BEFORE DELETE FOR EACH ROW trigger (tgtype 11) calling public.soft_delete.
    Each has soft_delete_policy: permissive, all commands, for PUBLIC (role OID 0, not the public schema), USING (deleted_at IS NULL), WITH CHECK true.

Tables without deleted_at, such as components and join tables, do not need this scheme. These are structural catalog checks. They do not delete a real row, create a table to test the hook, run the views or prove they match production, and policies written differently but equivalently will fail. They protect this app's expected structure, not all application behavior.

On success, ordinary objects use local rls, and the privileged functions and event triggers use luay.

## Failures and interruption

SQL errors before COMMIT roll back, leaving old objects and data intact. On failure or a caught signal (exit 130, 143 or 129), cleanup ignores further signals, terminates only this invocation's worker, found by its unique application_name, and removes temporary files that match the script's own naming pattern. It keeps the original exit status. An open transaction rolls back when terminated, but cleanup cannot undo a COMMIT that finished. A lost connection near COMMIT makes the outcome uncertain, so review the log before retrying. SIGKILL or a machine crash skips cleanup.
