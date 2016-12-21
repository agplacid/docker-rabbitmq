NS = vp
NAME = rabbitmq
APP_VERSION = 3.6.5
IMAGE_VERSION = 2.1
VERSION = $(APP_VERSION)-$(IMAGE_VERSION)
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME)

GITHUB_REPO = docker-rabbitmq
DOCKER_REPO = rabbitmq
BUILD_BRANCH = master

# VOLUME_ARGS = --tmpfs /var/lib/rabbitmq/mnesia:size=128M
ENV_ARGS = --env-file default.env 
DSHELL = bash -l

-include ../Makefile.inc

.PHONY: all build test release shell run start stop rm rmi default

all: build

checkout:
	@git checkout $(BUILD_BRANCH)

build:
	@docker build -t $(LOCAL_TAG) --force-rm .
	@$(MAKE) tag
	@$(MAKE) dclean

tag:
	@docker tag $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --force-rm --no-cache .
	@$(MAKE) dclean

test:
	@rspec ./tests/*.rb

commit:
	@git add -A .
	@git commit

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) $(DSHELL)

run:
	@docker run -it --rm --name $(NAME) $(LOCAL_TAG) $(DSHELL)

launch:
	@docker run -d --name $(NAME) -h $(NAME).local $(ENV_ARGS) $(VOLUME_ARGS) $(LOCAL_TAG)

launch-net:
	docker run -d --name $(NAME) -h $(NAME).local $(ENV_ARGS) $(VOLUME_ARGS) --network=local --net-alias $(NAME).local $(LOCAL_TAG)

# launch-dev:
# 	@docker run -d --name $(NAME)-alpha -h $(NAME)-alpha.local --network=local --net-alias $(NAME)-alpha.local $(ENV_ARGS) $(VOLUME_ARGS) $(LOCAL_TAG)
# 	@docker run -d --name $(NAME)-beta -h $(NAME)-beta.local --network=local --net-alias $(NAME)-beta.local $(ENV_ARGS) $(VOLUME_ARGS) $(LOCAL_TAG)

# rmf-dev:
# 	@docker rm -f $(NAME)-alpha
# 	@docker rm -f $(NAME)-beta

launch-as-dep:
	@$(MAKE) launch-dev

rmf-as-dep:
	@$(MAKE) rmf-dev

# create-network:
# 	@docker network create -d bridge local

# proxies-up:
# 	@cd ../docker-aptcacher-ng && make remote-persist

logs:
	@docker logs $(NAME)

logsf:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	-@docker kill $(NAME)

stop:
	-@docker stop $(NAME)

rm:
	-@docker rm $(NAME)

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

rmf:
	@docker rm --force $(NAME)

kube-deploy:
	@kubectl create -f kubernetes/$(NAME)-deployment-alpha.yaml --record
	@kubectl create -f kubernetes/$(NAME)-deployment-beta.yaml --record

kube-deploy-edit:
	@kubectl edit deployment/$(NAME)
	@$(MAKE) kube-rollout-status

kube-deploy-rollback:
	@kubectl rollout undo deployment/$(NAME)

kube-rollout-status:
	@kubectl rollout status deployment/$(NAME)

kube-rollout-history:
	@kubectl rollout history deployment/$(NAME)

kube-delete-deployment:
	@kubectl delete deployment/$(NAME)-alpha
	@kubectl delete deployment/$(NAME)-beta

kube-deploy-service:
	@kubectl create -f kubernetes/$(NAME)-service-alpha.yaml
	@kubectl create -f kubernetes/$(NAME)-service-beta.yaml

kube-delete-service:
	@kubectl delete svc $(NAME)-alpha
	@kubectl delete svc $(NAME)-beta

kube-apply-service:
	@kubectl apply -f kubernetes/$(NAME)-service.yaml

kube-logsf:
	@kubectl logs -f $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-logsft:
	@kubectl logs -f --tail=25 $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-shell:
	@kubectl exec -ti $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1) -- bash

default: build