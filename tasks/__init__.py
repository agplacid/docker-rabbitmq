import os
import glob

from invoke import Collection, task

from . import test, dc, kube


COLLECTIONS = [test, dc, kube]

ns = Collection()
for c in COLLECTIONS:
    ns.add_collection(c)


ns.configure(dict(
    project='rabbitmq',
    repo='docker-rabbitmq',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER'),
        org=os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')),
        name='rabbitmq',
        tag='%s/%s:latest' % (
            os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')), 'rabbitmq'
        ),
        shell='bash'
    ),
    kube=dict(
        environment='production'
    )
))
