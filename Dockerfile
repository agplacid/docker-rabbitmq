FROM callforamerica/lang-erlang:18.1

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="alpine" \
        os.version="3.3"

LABEL   lang.name="erlang" \
        lang.version="18.1"

LABEL   app.name="rabbitmq" \
        app.version="3.6.0" \
        autocluster.version="0.4.1"

ENV     RABBITMQ_VERSION=3.6.0 \
        RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION=0.4.1

ENV     RABBITMQ_HOME=/srv/rabbitmq \
        PLUGINS_DIR=/srv/rabbitmq/plugins \
        ENABLED_PLUGINS_FILE=/srv/rabbitmq/etc/rabbitmq/enabled_plugins \
        RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq

ENV     HOME=$RABBITMQ_HOME \
        PATH=$RABBITMQ_HOME/sbin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     RABBITMQ_LOGS=- \
        RABBITMQ_SASL_LOGS=- \
        RABBITMQ_USE_LONGNAME=false \
        RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="+A128 +P 1048576 -kernel inet_dist_listen_min 11500 inet_dist_listen_max 11999"

ENV     AUTOCLUSTER_TYPE=etcd \
        CLUSTER_NAME=rabbitmq \
        KUBERNETES_HOSTNAME_FIX=true

VOLUME  ["/var/lib/rabbitmq"]

EXPOSE  4369 5671 5672 15671 11500-11999 15672 61613

USER    rabbitmq

WORKDIR /srv/rabbitmq

CMD     ["/usr/bin/entrypoint"]
