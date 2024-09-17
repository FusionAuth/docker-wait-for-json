## Example usage:

Sample `docker-compose.yml`:

```yaml
version: '3'

services:
  startup_services:
    image: fusionauth/wait-for-json
    depends_on:
      - fusionauth
    networks:
      - fusionauth_net
    command: fusionauth:9011/api/status

  db:
    image: postgres:16.0-bookworm
    environment:
      PGDATA: /var/lib/postgresql/data/pgdata
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U postgres" ]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - db_net
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/postgresql/data

  search:
    image: opensearchproject/opensearch:2.11.0
    environment:
      cluster.name: fusionauth
      discovery.type: single-node
      node.name: search
      plugins.security.disabled: true
      bootstrap.memory_lock: true
      OPENSEARCH_JAVA_OPTS: ${OPENSEARCH_JAVA_OPTS}
    healthcheck:
      interval: 10s
      retries: 80
      test: curl --write-out 'HTTP %{http_code}' --fail --silent --output /dev/null http://localhost:9200/
    restart: unless-stopped
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - 9200:9200 # REST API
      - 9600:9600 # Performance Analyzer
    volumes:
      - search_data:/usr/share/opensearch/data
    networks:
      - search_net

  fusionauth:
    image: fusionauth/fusionauth-app:latest
    depends_on:
      db:
        condition: service_healthy
      search:
        condition: service_healthy
    environment:
      DATABASE_URL: jdbc:postgresql://db:5432/fusionauth
      DATABASE_ROOT_USERNAME: ${POSTGRES_USER}
      DATABASE_ROOT_PASSWORD: ${POSTGRES_PASSWORD}
      DATABASE_USERNAME: ${DATABASE_USERNAME}
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
      FUSIONAUTH_APP_MEMORY: ${FUSIONAUTH_APP_MEMORY}
      FUSIONAUTH_APP_RUNTIME_MODE: ${FUSIONAUTH_APP_RUNTIME_MODE}
      FUSIONAUTH_APP_URL: http://fusionauth:9011
      SEARCH_SERVERS: http://search:9200
      SEARCH_TYPE: elasticsearch
      FUSIONAUTH_APP_KICKSTART_FILE: ${FUSIONAUTH_APP_KICKSTART_FILE}
    networks:
      - db_net
      - search_net
      - fusionauth_net
    restart: unless-stopped
    ports:
      - 9011:9011
    volumes:
      - fusionauth_config:/usr/local/fusionauth/config
      - ./kickstart:/usr/local/fusionauth/kickstart

networks:
  db_net:
    driver: bridge
  fusionauth_net:
    driver: bridge
  search_net:
    driver: bridge

volumes:
  db_data:
  fusionauth_config:
  search_data:
```

Then, to guarantee that `fusionauth` and its dependencies are ready before running proceeding by waiting on a JSON response from `fusionauth:9011/api/status`:

```bash
$ docker-compose run --rm startup_services
```

You may specify multiple endpoints to wait for JSON response from by seperating them with spaces in the `command` directive:

```yaml
  startup_services:
    image: fusionauth/wait-for-json
    depends_on:
      - fusionauth
    networks:
      - fusionauth_net
    command: fusionauth:9011/api/foo fusionauth:9011/api/bar fusionauth:9011/api/baz
```

```yaml
  start_dependencies:
    image: fusionauth/wait-for-json
    environment:
      - SLEEP_LENGTH: 1
      - TIMEOUT_LENGTH: 60
      - JSON_TYPE: array
```

By default, there will be a 2 second sleep time between each check. You can modify this by setting the `SLEEP_LENGTH` environment variable:

```yaml
  start_dependencies:
    image: fusionauth/wait-for-json
    environment:
      - SLEEP_LENGTH: 0.5
```

By default, there will be a 300 seconds timeout before cancelling the wait_for. You can modify this by setting the `TIMEOUT_LENGTH` environment variable:

```yaml
  start_dependencies:
    image: fusionauth/wait-for-json
    environment:
      - SLEEP_LENGTH: 1
      - TIMEOUT_LENGTH: 60
```

By default, we will wait for a JSON object to be returned from the specified endpoints.  You can modify this by setting the `JSON_TYPE` environment variable to one of null, boolean, number, string, array or object:

```yaml
  start_dependencies:
    image: fusionauth/wait-for-json
    environment:
      - SLEEP_LENGTH: 1
      - TIMEOUT_LENGTH: 60
      - JSON_TYPE: array
```
