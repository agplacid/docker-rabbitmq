FROM centos:6

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="centos" \
        os.version="6"

LABEL   lang.name="erlang" \
        lang.version="19.0.4"

LABEL   app.name="rabbitmq" \
        app.version="3.6.5"

ENV     ERLANG_VERSION=19.0.4 \
        RABBITMQ_VERSION=3.6.5

ENV     HOME=/opt/rabbitmq
ENV     PATH=$HOME/bin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     RABBITMQ_LOGS=- \
        RABBITMQ_SASL_LOGS=- \
        RABBITMQ_LOG_LEVEL=info \
        RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-kernel inet_dist_listen_min 11500 inet_dist_listen_max 11999 inet_default_connect_options [{nodelay,true}]"        

VOLUME  ["/var/lib/rabbitmq"]

EXPOSE  4369 5672 15672 11500-11999 

# USER    rabbitmq

WORKDIR /opt/rabbitmq

CMD     ["/usr/bin/entrypoint"]
