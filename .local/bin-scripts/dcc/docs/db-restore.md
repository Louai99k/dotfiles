# dcc db-restore

Restores a snapshot made by dcc db-snapshot, using docker exec in data-management-db-1. Script: restore-database-snapshot.sh. PostgreSQL tools run inside the container; no Python or host PostgreSQL installation is needed. Uses the explicit local Docker socket and local PostgreSQL Unix socket. Default PostgreSQL superuser: luay (override with --user ROLE).

Restore over the snapshot's original database, or into another one:

    dcc db-restore ~/db-snapshots/before-wdcc
    dcc db-restore ~/db-snapshots/master-before-changes --database local_db

Options:

    --database TARGET  Database to replace. Default: the snapshot's original database.
    --user ROLE        PostgreSQL superuser to connect as. Default: luay.
    --yes              Opt into unattended replacement, skipping the confirmation prompt.
    -h, --help         Show this help. Nothing else runs, even with other options.

Stop backend and disconnect target pgAdmin sessions first. The script asks for the target database name as confirmation; --yes opts into unattended replacement. It does not terminate application sessions. It refuses system/template database targets.

Restore checks the archive/metadata checksums, creates a uniquely named staging database, and invokes pg_restore --exit-on-error --single-transaction. After successfully loading data and database properties, it blocks target reconnects, checks for active clients, then swaps names in a transaction. The original target remains as dcc_previous_<token> with connections disabled; nothing automatically drops it. This also removes the possibility of extra objects from changes made after the snapshot surviving under the restored name.

Checksums are verified against a fixed list of snapshot files rather than trusting paths or options from the checksum file. A flock on the snapshot's dump serializes restores of the same snapshot and is released on process exit. A superuser is required to preserve ownership and event triggers. Staging and rollback names contain only lowercase letters, digits and underscores, and SQL or shell metadata is never evaluated.

On an ordinary failure the original is retained and its prior connection availability is restored. Failed staging databases remain for inspection. On interruption near COMMIT, the outcome can be uncertain: inspect staging, target and rollback names before retrying. A cleanup call terminates only this invocation's staged pg_restore worker if docker exec outlives its client. Rollback/staging databases consume space until explicitly removed. Database ACL privileges are restored; grantor identity is not separately reconstructed.

Requires existing local roles/tablespaces/extension packages, Bash, Docker, GNU coreutils, awk, sed and flock. No cluster-wide roles, replication slots, server configuration or external tablespace files are backed up. Missing cluster prerequisites cause restore failure; scripts never create substitute roles. Snapshot SQL is trusted executable PostgreSQL backup material; use your own snapshots.

No dumps, restores, tests or verification commands were executed while preparing this script.
