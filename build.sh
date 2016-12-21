#!/bin/bash

set -e

readonly APP=rabbitmq
readonly USER=$APP

function get_apt_version {
    local app=${1:-$APP}
    local vvar=${2:-$app}; vvar=${vvar^^}_VERSION
    local version=${!vvar}
    apt-cache madison $app | awk '{print $3}' | grep $version | sort -rn | head -1
}

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $USER ..."
useradd --system --home-dir ~ --create-home --shell /bin/false --user-group $USER


echo "Installing essentials ..."
apt-get update
apt-get install -y curl


echo "Installing erlang and $APP repos ..."
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > /etc/apt/sources.list.d/erlang.list
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 0A9AF2115F4687BD29803A206B73A36E6026DFCA
echo 'deb http://www.rabbitmq.com/debian testing main' > /etc/apt/sources.list.d/rabbitmq.list
apt-get update


echo "Installing $APP ..."
apt_erlang_version=$(get_apt_version erlang-nox erlang)
apt_rabbitmq_version=$(get_apt_version rabbitmq-server rabbitmq)
echo "erlang: $apt_erlang_version  rabbitmq: $apt_rabbitmq_version"

apt-get install -y \
    erlang-nox=$apt_erlang_version \
    rabbitmq-server=$apt_rabbitmq_version


echo "Adding $APP environment to .bashrc ..."
tee /etc/profile.d/40-${APP}-env.sh <<'EOF'
if [ -d /usr/lib/rabbitmq/bin ]
then
    export PATH=/usr/local/bin:/usr/lib/rabbitmq/bin:$PATH
fi

export RABBITMQ_LOGS=-
export RABBITMQ_SASL_LOGS=-
export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-kernel inet_dist_listen_min 11500 inet_dist_listen_max 11999 $RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS"
EOF


echo "Adding bash profile hook to write erlang cookie ..."
tee /etc/profile.d/50-${APP}-init.sh <<'EOF'
if [[ $KUBERNETES_HOSTNAME_FIX = true ]]; then
    eval $(kube-hostname-fix enable)
fi

# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump
EOF


echo "Cleaning up unnecessary files ..."
rm -rf \
    /usr/share/doc/rabbitmq-server \
    /etc/logrotate.d/rabbitmq-server \
    /lib/systemd/system/rabbitmq-server.service


echo "Setting permissions ..."
chown -R $USER:$USER ~ /etc/rabbitmq /var/lib/rabbitmq /usr/local/bin


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
