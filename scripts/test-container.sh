#!/bin/bash

set -e

: ${NAME:=$(basename $PWD | cut -d'-' -f2)}
: ${DELAY:=10}
: ${SUCCESS_STRING:='^Server startup complete'}
: ${TEST_PORTS:=5672,15672}


sleep $DELAY

docker ps | grep -q $NAME && \
    echo "* Container $NAME Running"

docker logs $NAME 2>/dev/null | grep -q "$SUCESS_STRING" && \
    echo "* Found '$SUCCESS_STRING' in docker logs "

for port in ${TEST_PORTS//,/ }; do
    docker exec $NAME bash -l -c "nc -z 127.0.0.1 $port" && \
        echo "* Port $port open"
done


docker exec $NAME bash -l -c "rabbitmqctl node_health_check | grep -q '^Health check passed'" && \
    echo "* rabbitmqctl node_health_check passed"

docker exec $NAME bash -l -c 'curl -s -u guest:guest http://localhost:15672/api/aliveness-test/%2F > /dev/null' && \
    echo "* RabbitMQ Management Interface passed aliveness-test"
