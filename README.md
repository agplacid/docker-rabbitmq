# RabbitMQ w/ Autoclustering

AMQP Message Bus dockerized, for use in a kubernetes pod.

NOTE: USER rabbitmq is currently disabled in the dockerfile due to the following problem:

Pod DNS in Kubernetes is a relatively new thing.  
Kubernetes still creates the pod using docker without a hostname, hostname cannot be changed in a container, hostname is also not resolvable.  

EPMD requires that this be resolvable.

I've fixed this by creating a dummy hostname bash script and place it at the beginning of the path: '/srv/rabbitmq/sbin/hostname-fix'.  This is linked in the entrypoint to '/srv/rabbitmq/sbin/hostname', and the same hostname is echo'd to /etc/hosts.

When using USER rabbitmq in the dockerfile permission is denied when trying to echo the hostname to /etc/hosts.  Changing the owner of /etc/hosts in docker also doesn't work. :(

Hopefully this is fixed in kubernetes soon, until then..