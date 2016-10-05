# RabbitMQ 3.5.6 dockerized with kubernetes fixes and manifests

![docker automated build](https://img.shields.io/docker/automated/callforamerica/rabbitmq.svg)
![docker pulls](https://img.shields.io/docker/pulls/callforamerica/rabbitmq.svg)

## Maintainer

Joe Black <joe@valuphone.com>

## Introduction 

Minimal image, the only plugin is rabbitmq-management.

## Build Environment

Build environment variables are often used in the build script as plug in variables that can be set in the Dockerfile to bump version numbers of the various things that are installed during the `docker build` phase.  

In the case of this image, however, erlang and rabbitmq are installed via apt-get simply to grab the most current version.  This is made possible by adding some third party repos to apt beforehand which make the packages for erlang 19.x and rabbitmq-server 3.5.x available.  The decision was made to still export these variables to the environment during the build process in order to make them available to the build script and the entrypoint script in a manner consistent with the rest of the images.

The following variables are currently ignored in the build and entrypoint scripts and are included for possible future use and consistency:

* `ERLANG_VERSION`
* `RABBITMQ_VERSION`

The following variables are used in the build script:

* `DUMB_INIT_VERSION`: value provided is used as the version of dumb-init to install. String, defaults to `1.1.3`.

## Run Environment

Run environment variables are used in the entrypoint script when rendering configuration templates and sometimes also for flow control in the entrypoint script.  These values can be provided when inheriting from the base dockerfile, or also specified at `docker run` as `-e` arguments, and in kubernetes manifests in the `env` array.

* `RABBITMQ_LOG_LEVEL`: value provided is lowercased and supplied as the value for the connection log_level tuple in `rabbitmq.config`  String, defaults to `info`

* `RABBITMQ_DISK_FREE_LIMIT`: value provided is supplied as the value of the `vm_memory_high_watermark` tuple in the `rabbitmq.config` file.  String, defaults to `50MB`

* `RABBITMQ_VM_MEMORY_HIGH_WATERMARK`: value provided is supplied as the value for the `vm_memory_high_watermark` in the `rabbitmq.config` file. String, defaults to `0.8`

In addition to these environment variables, there are numerous other environment variables recognized by the rabbitmq bash script, several of these can be seen used in the current Dockerfile.  Refer to [https://www.rabbitmq.com/configure.html](https://www.rabbitmq.com/configure.html) for more details.

Also there are some environment variables recognized by the erlang vm itself.  These often start with `ERL_`.

: ${RABBITMQ_LOG_LEVEL:=info}
: ${RABBITMQ_DISK_FREE_LIMIT:=50MB}
: ${RABBITMQ_VM_MEMORY_HIGH_WATERMARK:=0.8}

## Instructions

### Running locally under docker

If building and running locally for quick testing, feel free to use the convenience targets in the Makefile.

`make launch`: launch under docker locally using the latest build version and default docker network.

`make launch-net`: launch under docker locally using the latest version and the docker network: `local`.  You can create this network if it doesn't exist with `make create-network`.

`make launch-deps`: Starts up local rabbitmq and couchdb servers for local testing. (requires the docker-couchdb and docker-rabbitmq projects to also be reachable as sibling directories)

`make logsf`: Tail the logs of the kazoo docker container you just launched

`make shell`: Exec's into the kazoo container you just launched with a bash shell

*There are way more convenience targets in the Makefile, be sure to check it out.*

### Running under docker using docker hub prebuilt image

All of our docker-* repos in github have automatic build pipelines setup with docker hub, reachable at [https://hub.docker.com/r/callforamerica/](https://hub.docker.com/r/callforamerica/).

This image resides at: [https://hub.docker.com/r/callforamerica/rabbitmq](https://hub.docker.com/r/callforamerica/rabbitmq), and under docker using the shortform: `callforamerica/rabbitmq`

You can run this docker hub image using the following docker run command:

```bash
docker run -d \
    --name rabbitmq \
    -h rabbitmq \
    -e "KAZOO_LOG_LEVEL=info" \
    callforamerica/rabbitmq:4
```
*It's reccomended to run rabbitmq without mapping any ports to the host machine and rather use the dns function in your cluster manager to do service discovery.*

Please use the Run Environment section above to determine which environment variables you will need to change here to get everything working correctly.

### Running under kubernetes

Edit the manifests under kubernetes/ to best reflect your environment and configuration.

You will need to create a kubernetes secret named `erlang-cookie` including the base64'd erlang-cookie under the key: `cookie` or update the deployment manifest to reflect your own name.  See kubernetes documentation for instructions on how to do this.

Create the kubernetes service: `make kube-deploy-service`

Create the kubernetes deployment: `make kube-deploy`

That's literally it


## Issues

### 1. Sometimes the build process will exit early due to a remote server error using apt-get

No idea why this happens but it only effects debian, lovely.  Careful consideration will be necessary to make sure building this image doesn't return early.  The build script sets the -e flag to ensure this isn't ignored silently.

### 2. Kubernetes Pod hostname's do not reflect it's PodIP assigned DNS. 

For certain containers running erlang, it can be extremely convenient for the environments hostname to be resolvable to it's ip address outside of the pod.  The hack I've done to work around this requires root privileges at runtime to add entries to the `/etc/hosts` and /etc/hostname file as both are mounted by kubernetes in the container as the root user at runtime, effectively breaking the ability to set a non root user in the dockerfile.  `USER rabbitmq` has been commented out in the dockerfile for this reason.  If you are not running in a kubernetes environment and do not plan to take advantage of this feature by providing `KUBERNETES_HOSTNAME_FIX=true` to the environment, you can feel free to inherit from this dockerfile and set USER kazoo, `KUBERNETES_HOSTNAME_FIX` is false by default.

I've fixed this by creating a dummy hostname bash script and place it at the beginning of the path: '/var/lib/rabbitmq/bin/hostname-fix'.  In the entrypoint script, if `KUBERNETES_HOSTNAME_FIX` is set, this script is linked at runtime to '/var/lib/rabbitmq/bin/hostname', and the environment variable `HOSTNAME` is set correctly, as well as creating entries in /etc/hosts and overwriting /etc/hostname.

If anyone knows of a better way to do this, please submit a pull request with a short explanation of the process you used.

### 3. Using gosu at the end of the entrypoint script breaks logging.

Using gosu at the end of the entrypoint script breaks a later bash script that uses su internally.  While rabbitmq still loads it doesn't output logs to stdout, breaking container logging conventions.  There could be other issues as well.  Since that later script is dropping priveleges at the end before executing the erlang virtual machine, it seems to be a minimal concern overall.