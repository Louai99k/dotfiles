# dcc db-down

Stops and removes the local database stack's containers with docker-compose down. This command runs directly from dcc, with no script.

    dcc db-down

Compose file: /home/luay/me/childcare/_childcare/database-docker/docker-compose.yml

Stops services db and pgadmin in compose project data-management. PostgreSQL data is in the ./postgres bind mount beside the compose file, so down does not delete it. Extra arguments are ignored.

Options:

    -h, --help  Show this help without stopping anything.
