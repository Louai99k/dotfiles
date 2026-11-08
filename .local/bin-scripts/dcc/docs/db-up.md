# dcc db-up

Starts the local database stack in the background with docker-compose up -d. This command runs directly from dcc, with no script.

    dcc db-up

Compose file: /home/luay/me/childcare/_childcare/database-docker/docker-compose.yml

Compose project data-management has two services, db and pgadmin. The db container, data-management-db-1, is the one dcc db-snapshot, dcc db-restore and dcc master-db-restore use. Extra arguments are ignored.

Options:

    -h, --help  Show this help without starting anything.
