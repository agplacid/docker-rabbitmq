# RabbitMQ (stable) w/ Kubernetes fixes & manifests

[![Build Status](https://travis-ci.org/sip-li/docker-rabbitmq.svg?branch=master)](https://travis-ci.org/sip-li/docker-rabbitmq) [![Docker Pulls](https://img.shields.io/docker/pulls/callforamerica/rabbitmq.svg)](https://store.docker.com/community/images/callforamerica/rabbitmq)

## Maintainer

Joe Black <joeblack949@gmail.com>

## Description

Minimal image with one plugin *(rabbitmq-management)*.  This image uses a custom version of Debian Linux (Jessie) that I designed weighing in at ~22MB compressed.

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

ref: [https://www.rabbitmq.com/configure.html](https://www.rabbitmq.com/configure.html)


## Usage

### Under docker (manual-build)

If building and running locally, feel free to use the convenience targets in the included `Makefile`.

* `make build`: rebuilds the docker image.
* `make launch`: launch for testing.
* `make logs`: tail the logs of the container.
* `make shell`: exec's into the docker container interactively with tty and bash shell.
* `make test`: test's the launched container.
* *and many others...*


### Under docker (pre-built)

All of our docker-* repos in github have CI pipelines that push to docker cloud/hub.  

This image is available at:
* [https://store.docker.com/community/images/callforamerica/rabbitmq](https://store.docker.com/community/images/callforamerica/rabbitmq)
*  [https://hub.docker.com/r/callforamerica/rabbitmq](https://hub.docker.com/r/callforamerica/).

and through docker itself: `docker pull callforamerica/rabbitmq`

To run:

```bash
docker run -d \
    --name rabbitmq \
    -h rabbitmq \
    callforamerica/rabbitmq
```

**NOTE:** Please reference the Run Environment section for a list of available environment variables.


### Under Kubernetes

Edit the manifests under `kubernetes/` to reflect your specific environment and configuration.

Create a secret for the erlang cookie:
```bash
kubectl create secret generic erlang-cookie --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

Create a secret for the rabbitmq credentials:
```bash
kubectl create secret generic rabbitmq-creds --from-literal=rabbitmq.user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=rabbitmq.pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

Deploy rabbitmq:
```bash
kubectl create -f kubernetes
```


## Issues

**ref:**  [https://github.com/sip-li/docker-rabbitmq/issues](https://github.com/sip-li/docker-rabbitmq/issues)
