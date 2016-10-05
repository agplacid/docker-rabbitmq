FROM callforamerica/debian

MAINTAINER joe <joe@valuphone.com>

LABEL   lang.name="erlang" \
        lang.version="19.1"

LABEL   app.name="rabbitmq" \
        app.version="3.6.5"

ENV     ERLANG_VERSION=19.1 \
        RABBITMQ_VERSION=3.6.5

ENV     HOME=/var/lib/rabbitmq

COPY    build.sh /tmp/build.sh
RUN     /tmp/build.sh

COPY    entrypoint /entrypoint       

ENV     ERL_MAX_PORTS=65536

ENV     RABBITMQ_LOG_LEVEL=info

EXPOSE  4369 5672 15672 11500-11999

# USER    rabbitmq

VOLUME  ["/var/lib/rabbitmq/mnesia"]

WORKDIR /var/lib/rabbitmq

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
