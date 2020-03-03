#!/bin/sh

: ${SLEEP_LENGTH:=2}
: ${TIMEOUT_LENGTH:=300}
: ${JSON_TYPE:=object}

wait_for() {
  START=$(date +%s)
  echo "Waiting for JSON response from $1..."
  while [[ "$(curl -s --retry-connrefused --retry 12 --retry-delay 5 --retry-max-time $TIMEOUT_LENGTH $1 | jq --raw-output type)" != "$JSON_TYPE" ]]
    do
    if [ $(($(date +%s) - $START)) -gt $TIMEOUT_LENGTH ]; then
        echo "Endpoint $1 did not reponse with a JSON object within $TIMEOUT_LENGTH seconds. Aborting..."
        exit 1
    fi
    sleep $SLEEP_LENGTH
  done
}

for var in "$@"
do
  endpoint=${var}
  wait_for $endpoint
done
