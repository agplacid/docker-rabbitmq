#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $APP

log::m-info "Installing erlang and $APP repos ..."
# build::apt::add-key 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
# echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > \
#     /etc/apt/sources.list.d/erlang.list
# build::apt::add-key 0A9AF2115F4687BD29803A206B73A36E6026DFCA

echo 'deb http://www.rabbitmq.com/debian testing main' > \
    /etc/apt/sources.list.d/rabbitmq.list
apt-get -q update


log::m-info "Installing essentials ..."
apt-get install -qq -y curl


log::m-info "Installing $APP ..."
apt_erl_vsn=$(build::apt::get-version erlang-nox erlang)
apt_rbt_vsn=$(build::apt::get-version rabbitmq-server rabbitmq)
log::m-info "apt versions:  erlang: $apt_erl_vsn rabbitmq: $apt_rbt_vsn"
apt-get install -qq -y \
    erlang-nox=$apt_erl_vsn \
    rabbitmq-server=$apt_rbt_vsn


log::m-info "Adding $APP environment to bash profile ..."
echo /usr/lib/rabbitmq/bin >> /etc/paths.d/20-${APP}
tee /etc/environment.d/40-${APP}-env <<'EOF'
export RABBITMQ_LOGS=-
export RABBITMQ_SASL_LOGS=-
export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-kernel inet_dist_listen_min 11500 inet_dist_listen_max 11999 $RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS"
EOF


log::m-info "Adding app init to entrypoint ..."
tee /etc/entrypoint.d/50-${APP}-init <<'EOF'
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump

fixattrs
EOF


log::m-info "Adding fix to ensure long hostnames work correctly ..."
echo 'unset HOSTNAME' >> /etc/profile.d/40-fix-hostname.sh

tee /etc/profile.d/60-${APP}-long-name.sh <<'EOF'
if [[ $USE_LONG_HOSTNAME == true || $ERLANG_HOSTNAME == 'long' || $KUBE_HOSTNAME == 'long' ]]; then
    export RABBITMQ_USE_LONGNAME=true
fi
EOF


tee /etc/fixattrs.d/40-${APP}-own-state-dirs <<EOF
$HOME true $USER:$USER 0775 0775
$HOME/.erlang.cookie false $USER:$USER 0600 0755
$HOME/mnesia true $USER:$USER 0777 0777
EOF


log::m-info "Cleaning up unnecessary files ..."
rm -rf \
    /usr/share/doc/rabbitmq-server \
    /etc/logrotate.d/rabbitmq-server \
    /lib/systemd/system/rabbitmq-server.service


log::m-info "Setting ownership & permissions ..."
chown -R $USER:$USER ~ /etc/rabbitmq /var/lib/rabbitmq /usr/local/bin


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
