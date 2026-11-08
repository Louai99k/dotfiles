# dcc master-db

Downloads production master database dumps from S3 into the pgAdmin storage folder, where dcc master-db-restore looks for them. Script: download-master-db.sh. Requires the AWS CLI with credentials that can read the bucket.

Download dumps dated today, or those matching a date or timestamp:

    dcc master-db
    dcc master-db -f 20261108
    dcc master-db -f 20261108120000

Delete local dumps first, then download:

    dcc master-db -d -f 20261108

Options:

    -f NAME     Match s3://mdc-db-dumps/*master_dump_NAME*. Default: today as YYYYMMDD.
    -d          Delete every master_dump_* file in the download folder, including sidecars.
    -h, --help  Show this help. Nothing else runs, even with other options.

Download folder: /home/luay/me/childcare/_childcare/database-docker/pgadmin/storage/admin_admin.com

A match also downloads the bundle's .roles.sql and .sha256 sidecars, which dcc master-db-restore requires. A date matches every dump from that day. Today's default uses the local date, so an older dump needs -f.

-d deletes as soon as it is parsed: before the download, and before any later invalid option is rejected. A failed download after -d leaves no local dumps. With no master_dump_* files present, -d fails and the script stops without downloading.
