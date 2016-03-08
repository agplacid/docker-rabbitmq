#!/bin/ash

echo "Installing Dependencies ..."
apk add --update \
    curl \
    tar \
    xz \
    bind-tools \
    bash

apk add \
    erlang-mnesia \
    erlang-public-key \
    erlang-crypto \
    erlang-ssl \
    erlang-sasl \
    erlang-asn1 \
    erlang-inets \
    erlang-os-mon \
    erlang-xmerl \
    erlang-eldap \
    erlang-syntax-tools

echo "Creating rabbitmq group & user ..."
addgroup rabbitmq
adduser -h $RABBITMQ_HOME -H -g rabbitmq -s /bin/bash -D -G rabbitmq rabbitmq

mkdir -p /srv /var/lib/rabbitmq

cd /srv
    echo "Downloading RabbitMQ ..."
    rmq_zip_url=https://github.com/rabbitmq/rabbitmq-server/releases/download
    rmq_zip_url=${rmq_zip_url}/rabbitmq_v$(echo $RABBITMQ_VERSION | tr '.' '_')
    rmq_zip_url=${rmq_zip_url}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz

    curl -sSL -o rmq.tar.xz $rmq_zip_url
    tar -xvf rmq.tar.xz
    mv rabbitmq_server-${RABBITMQ_VERSION} rabbitmq
    rm -f rmq.tar.xz
    
    touch /srv/rabbitmq/etc/rabbitmq/enabled_plugins
    rabbitmq-plugins enable --offline rabbitmq_management
    
    echo "Downloading RabbitMQ Autocluster ..."
    rmq_ac_url=https://github.com/aweber/rabbitmq-autocluster/releases/download
    rmq_ac_url=${rmq_ac_url}/${RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION}
    rmq_ac_url=${rmq_ac_url}/autocluster-${RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION}.ez

    curl -sSL -o ${PLUGINS_DIR}/autocluster-${RABBITMQ_AUTOCLUSTER_PLUGIN_VERSION}.ez $rmq_ac_url

    echo "Setting Ownership & Permissions ..."
    chown -R rabbitmq:rabbitmq $RABBITMQ_HOME
    chown -R rabbitmq:rabbitmq $RABBITMQ_MNESIA_BASE
    chown rabbitmq:rabbitmq /usr/bin/entrypoint
    chmod a+x /usr/bin/entrypoint

echo "Writing SSL Rabbit Config ..."
tee /srv/rabbitmq/etc/rabbitmq/ssl.config <<EOF
[
  { rabbit, [ 
    { tcp_listeners, [ ] },
    { ssl_listeners, [ 5671 ] },
    { ssl_options,  [ 
      { certfile,   "CERTFILE" },
      { keyfile,    "KEYFILE" },
      { cacertfile, "CAFILE" },
      { verify,   verify_peer },
      { fail_if_no_peer_cert, true } ] },
    { loopback_users, [] }
    ]},
    { rabbitmq_management, [
        { listener, [ 
          { port, 15671 }, 
          { ssl, true },
          { ssl_opts, [ 
              { certfile,   "CERTFILE" },
              { keyfile,    "KEYFILE" },
              { cacertfile, "CAFILE" },
          { verify,   verify_none },
          { fail_if_no_peer_cert, false } ] } ] }
    ]
  }
].
EOF

echo "Writing Standard Rabbit Config ..."
tee /srv/rabbitmq/etc/rabbitmq/standard.config <<EOF
[
  { rabbit, [
      { tcp_listeners, [ 5672 ] },
      { ssl_listeners, [ ] },
      { loopback_users, [] }
    ]
  },
  { rabbitmq_management, [
      { listener, [
        { port, 15672 },
        { ssl, false } 
        ]
      }
    ]
  }
].
EOF

echo "Writing Hostname override fix ..."
tee /srv/rabbitmq/sbin/hostname-fix <<'EOF'
#!/bin/bash

fqdn() {
    local IP=$(/bin/hostname -i | sed 's/\./-/g')
    local DOMAIN='default.pod.cluster.local'
    echo "${IP}.${DOMAIN}"
}

short() {
    local IP=$(/bin/hostname -i | sed 's/\./-/g')
    echo $IP
}

ip() {
    /bin/hostname -i
}

if [[ "$1" == "-f" ]]; then
    fqdn
elif [[ "$1" == "-s" ]]; then
    short
elif [[ "$1" == "-i" ]]; then
    ip
else
    short
fi
EOF
chmod +x /srv/rabbitmq/sbin/hostname-fix

chown rabbitmq:rabbitmq /bin/hostname /etc/hosts

echo "dir ls for /etc/hosts"
ls -la /etc/hosts

echo "Cleaning up ..."
apk del --purge tar xz 
rm -rf /var/cache/apk/*
rm -r /tmp/setup.sh

