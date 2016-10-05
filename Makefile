NS = vp
NAME = rabbitmq
APP_VERSION = 3.6.5
IMAGE_VERSION = 2.1
VERSION = $(APP_VERSION)-$(IMAGE_VERSION)
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME):$(VERSION)

GITHUB_REPO = docker-rabbitmq
DOCKER_REPO = rabbitmq
BUILD_BRANCH = master


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

dclean:
	@-docker ps -aq | gxargs -I{} docker rm {} 2> /dev/null || true
	@-docker images -f dangling=true -q | xargs docker rmi
	@-docker volume ls -f dangling=true -q | xargs docker volume rm

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) /bin/bash

run:
	@docker run -it --rm --name $(NAME) $(LOCAL_TAG) bash

launch:
	@docker run -d -h $(NAME).local --name $(NAME) -e "RABBITMQ_USE_LONGNAME=true" --tmpfs /var/lib/rabbitmq/mnesia:size=512M $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME)-alpha -h rabbitmq-alpha -e "KUBERNETES_USE_SHORTNAME=true" --network=local --net-alias rabbitmq-alpha $(LOCAL_TAG)
	@docker run -d --name $(NAME)-beta -h rabbitmq-beta -e "KUBERNETES_USE_SHORTNAME=true" --network=local --net-alias rabbitmq-beta $(LOCAL_TAG)

create-network:
	@docker network create -d bridge local

proxies-up:
	@cd ../docker-aptcacher-ng && make remote-persist
	@cd ../docker-squid && make remote-persist

logs:
	@docker logs $(NAME)

logsf:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	-@docker kill $(NAME)-alpha
	-@docker kill $(NAME)-beta

stop:
	-@docker stop $(NAME)-alpha
	-@docker stop $(NAME)-beta

rm:
	-@docker rm $(NAME)-alpha
	-@docker rm $(NAME)-beta

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