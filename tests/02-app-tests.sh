echo::header "Application Tests for $NAME ..."

echo::test "RabbitMQ node_health_check"
docker exec $NAME bash -l -c "rabbitmqctl node_health_check | grep -q '^Health check passed'"
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "RabbitMQ Management Interface aliveness-test"
docker exec $NAME bash -l -c 'curl -s -u guest:guest http://localhost:15672/api/aliveness-test/%2F > /dev/null'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo >&2
