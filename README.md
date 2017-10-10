# RabbitMQ (stable) w/ Kubernetes fixes & manifests

[![Build Status](https://travis-ci.org/telephoneorg/docker-rabbitmq.svg?branch=master)](https://travis-ci.org/telephoneorg/docker-rabbitmq) [![Docker Pulls](https://img.shields.io/docker/pulls/telephoneorg/rabbitmq.svg)](https://hub.docker.com/r/telephoneorg/rabbitmq) [![Size/Layers](https://images.microbadger.com/badges/image/telephoneorg/rabbitmq.svg)](https://microbadger.com/images/telephoneorg/rabbitmq) [![Github Repo](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/telephoneorg/docker-rabbitmq)


## Maintainer
Joe Black | <me@joeblack.nyc> | [github](https://github.com/joeblackwaslike)


## Description
Minimal image with one plugin *(rabbitmq-management)*.  This image uses a custom, minimal version of Debian Linux.


## Build Environment
Build environment variables are often used in the build script to bump version numbers and set other options during the docker build phase.  Their values can be overridden using a build argument of the same name.
* `ERLANG_VERSION`
* `RABBITMQ_VERSION`

The following variables are standard in most of our dockerfiles to reduce duplication and make scripts reusable among different projects:
* `APP`: rabbitmq
* `USER`: rabbitmq
* `HOME` /var/lib/rabbitmq


## Run Environment
Run environment variables are used in the entrypoint script to render configuration templates, perform flow control, etc.  These values can be overridden when inheriting from the base dockerfile, specified during `docker run`, or in kubernetes manifests in the `env` array.
* `RABBITMQ_LOG_LEVEL`: lowercased and used as the value for the connection log_level tuple in `rabbitmq.config`.  Defaults to `info`.
* `RABBITMQ_DISK_FREE_LIMIT`: used as the value for the `vm_memory_high_watermark` tuple in the `rabbitmq.config` file.  Defaults to `50MB`.
* `RABBITMQ_VM_MEMORY_HIGH_WATERMARK`: used as the value for the `vm_memory_high_watermark` in the `rabbitmq.config` file.  Defaults to `0.8`.
* `RABBITMQ_ENABLED_PLUGINS`: `,`'s are replaced with ` `'s and fed as positional arguments to `rabbitmq-plugins enable --offline` before starting rabbitmq.  Defaults to `rabbitmq_management,rabbitmq_management_agent`.

*In addition to these, there are numerous other variables recognized by the rabbitmq bash script.*

ref: https://www.rabbitmq.com/configure.html


## Usage
### Under docker (pre-built)
All of our docker-* repos in github have CI pipelines that push to docker cloud/hub.  

This image is available at:
* https://hub.docker.com/r/telephoneorg/rabbitmq
* https://store.docker.com/community/images/telephoneorg/rabbitmq
* `docker pull telephoneorg/rabbitmq`

To run:

```bash
docker run -d \
    --name rabbitmq \
    -h rabbitmq \
    -e "ERLANG_COOKIE=test-cookie" \
    -e "RABBITMQ_USE_LONGNAME=true" \
    telephoneorg/rabbitmq
```

**NOTE:** Please reference the Run Environment section for a list of available environment variables.


### Under docker-compose
Pull the images
```bash
docker-compose pull
```

Start application and dependencies
```bash
# start in foreground
docker-compose up --abort-on-container-exit

# start in background
docker-compose up -d
```


### Under Kubernetes
Edit the manifests under `kubernetes/<environment>` to reflect your specific environment and configuration.

Create a secret for the erlang cookie:
```bash
kubectl create secret generic erlang --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

Create a secret for the rabbitmq credentials:
```bash
kubectl create secret generic rabbitmq --from-literal=rabbitmq.user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=rabbitmq.pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

Deploy rabbitmq:
```bash
kubectl create -f kubernetes/<environment>
```
