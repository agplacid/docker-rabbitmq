#!/bin/bash

ARCH=x86_64


set -e


echo "Creating user and group for rabbitmq ..."
groupadd rabbitmq
useradd --home-dir /opt/rabbitmq --shell /bin/bash --comment 'rabbitmq user' -g rabbitmq --create-home rabbitmq

mkdir -p /opt/rabbitmq/bin

echo "Installing dependencies ..."
yum update -y
yum install -y epel-release
yum install -y socat


echo "Installing erlang ..."
rpm -Uvh https://github.com/rabbitmq/erlang-rpm/releases/download/v1.4.1/erlang-${ERLANG_VERSION}-1.el6.${ARCH}.rpm


echo "Installing rabbitmq ..."
rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
rpm -Uvh --nodeps https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-${RABBITMQ_VERSION}-1.noarch.rpm


echo "Writing rabbitmq.config ..."
tee /etc/rabbitmq/rabbitmq.config <<EOF
[
{rabbit, [{disk_free_limit, 5242880}
          ,{vm_memory_high_watermark, 0.8}
          ,{loopback_users, []}
         ]},
{rabbitmq_management, [{rates_mode, none}]},
{rabbitmq_management_agent, [{rates_mode, none}]}
].
EOF

echo "Writing enabled_plugins ..."
tee /etc/rabbitmq/enabled_plugins <<EOF
[rabbitmq_management].
EOF


echo "Writing Hostname override fix ..."
tee /opt/rabbitmq/bin/hostname-fix <<'EOF'
#!/bin/bash

fqdn() {
    local IP=$(/bin/hostname -i | sed 's/\./-/g')
    local DOMAIN='default.pod.cluster.local'
    echo "${IP}.${DOMAIN}"
}

short() {
    local IP=$(/bin/hostname -i | cut -d' ' -f1 | sed 's/\./-/g')
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


echo "Writing .bashrc ..."
tee /opt/rabbitmq/.bashrc <<'EOF'
#!/bin/bash

if [ "$KUBERNETES_HOSTNAME_FIX" == true ]; then
    if [ "$RABBITMQ_USE_LONGNAME" == true ]; then
        export HOSTNAME=$(hostname -f)
    else
        export HOSTNAME=$(hostname)
    fi
fi
EOF


echo "Setting permissions ..."
chown -R rabbitmq:rabbitmq /etc/rabbitmq /opt/rabbitmq
chmod +x /opt/rabbitmq/bin/hostname-fix


echo "Cleaning up ..."
yum clean all
rm -r /tmp/setup.sh
