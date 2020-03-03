## Example usage:

Sample `docker-compose.yml`:

```yaml
version: '3'

services:
  startup_services:
    image: trevorcsmith/wait-for-json
    depends_on:
      - fusionauth
    networks:
      - fusionauth
    command: fusionauth:9011/api/status

  db:
    image: postgres:9.6
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - 54320:5432
    networks:
      - db
    restart: unless-stopped

  search:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.3.1
    environment:
      cluster.name: fusionauth
      bootstrap.memory_lock: "true"
      ES_JAVA_OPTS: "${ES_JAVA_OPTS}"
    ports:
    - 9200:9200
    - 9300:9300
    networks:
      - search
    restart: unless-stopped
    ulimits:
      memlock:
        soft: -1
        hard: -1

  fusionauth:
    image: fusionauth/fusionauth-app:latest
    depends_on:
      - db
      - search
    environment:
      DATABASE_URL: jdbc:postgresql://db:5432/fusionauth
      DATABASE_ROOT_USER: ${POSTGRES_USER}
      DATABASE_ROOT_PASSWORD: ${POSTGRES_PASSWORD}
      DATABASE_USER: ${DATABASE_USER}
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
      FUSIONAUTH_MEMORY: ${FUSIONAUTH_MEMORY}
      FUSIONAUTH_SEARCH_SERVERS: http://search:9200
      FUSIONAUTH_URL: http://fusionauth:9010
      FUSIONAUTH_KICKSTART: /usr/local/fusionauth/kickstart.json
    networks:
     - db
     - fusionauth
     - search
    restart: unless-stopped
    ports:
      - 9010:9011
    volumes:
      - ./kickstart.json:/usr/local/fusionauth/kickstart.json

networks:
  db:
    driver: bridge
  fusionauth:
    driver: bridge
  search:
    driver: bridge
```

Then, to guarantee that `fusionauth` and its dependencies are ready before running proceeding by waiting on a JSON response from `fusionauth:9011/api/status`:

```bash
$ docker-compose run --rm startup_services
```

By default, there will be a 2 second sleep time between each check. You can modify this by setting the `SLEEP_LENGTH` environment variable:

```yaml
  start_dependencies:
    image: trevorcsmith/wait-for-json
    environment:
      - SLEEP_LENGTH: 0.5
```

By default, there will be a 300 seconds timeout before cancelling the wait_for. You can modify this by setting the `TIMEOUT_LENGTH` environment variable:

```yaml
  start_dependencies:
    image: trevorcsmith/wait-for-json
    environment:
      - SLEEP_LENGTH: 1
      - TIMEOUT_LENGTH: 60
```

By default, we will wait for a JSON object to be returned from the specified endpoints.  You can modify this by setting the `JSON_TYPE` environment variable to one of null, boolean, number, string, array or object:

```yaml
  start_dependencies:
    image: trevorcsmith/wait-for-json
    environment:
      - SLEEP_LENGTH: 1
      - TIMEOUT_LENGTH: 60
      - JSON_TYPE: array
```
