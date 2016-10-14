FROM callforamerica/debian

MAINTAINER joe <joe@valuphone.com>

ARG     ERLANG_VERSION
ARG     RABBITMQ_VERSION

ENV     ERLANG_VERSION=${ERLANG_VERSION:-19.1} \
        RABBITMQ_VERSION=${RABBITMQ_VERSION:-3.6.5}

LABEL   lang.erlang.version=$ERLANG_VERSION
LABEL   app.rabbitmq.version=$RABBITMQ_VERSION

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
