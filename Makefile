SHELL = /bin/zsh
SHELLFLAGS = -ilc

NAME := $(shell basename $$PWD | cut -d'-' -f2)
DOCKER_REPO = callforamerica
DOCKER_TAG := $(DOCKER_REPO)/$(NAME):latest

GITHUB_REPO = $(shell basename $$PWD)
BUILD_BRANCH = master

CSHELL = bash -l
ENV_ARGS = --env-file default.env
# VOLUME_ARGS = --tmpfs /var/lib/rabbitmq/mnesia:size=128M

-include ../Makefile.inc

.PHONY: all build rebuild test run launch shell launch-as-dep rmf-as-dep
.PHONY: logs start kill stop rm rmi rmf kube-deploy kube-delete default

build:
	@docker build -t $(DOCKER_TAG) --force-rm .
	@-$(MAKE) dclean

rebuild:
	@docker build -t $(DOCKER_TAG) --force-rm --no-cache .
	@-$(MAKE) dclean

test:
	@scripts/test-container.sh

run:
	@docker run -it --rm --name $(NAME) $(DOCKER_TAG) $(CSHELL)

launch:
	@docker run -d --name $(NAME) -h $(NAME) $(ENV_ARGS) $(VOLUME_ARGS) $(DOCKER_TAG)

shell:
	@docker exec -ti $(NAME) $(CSHELL)

launch-as-dep:
	@docker run -d --name $(NAME)-alpha -h $(NAME) $(ENV_ARGS) $(VOLUME_ARGS) $(DOCKER_TAG)
	@docker run -d --name $(NAME)-beta -h $(NAME) $(ENV_ARGS) $(VOLUME_ARGS) $(DOCKER_TAG)

rmf-as-dep:
	@docker rm -f $(NAME)-alpha
	@docker rm -f $(NAME)-beta

logs:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	@-docker kill $(NAME)

stop:
	@-docker stop $(NAME)

rm:
	@-docker rm $(NAME)

rmi:
	@docker rmi $(DOCKER_TAG)

rmf:
	@docker rm --force $(NAME)

push:
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@docker push $(REPO)

kube-deploy:
	@kubectl create -f kubernetes/$(NAME)-service-alpha.yaml
	@kubectl create -f kubernetes/$(NAME)-service-beta.yaml
	@kubectl create -f kubernetes/$(NAME)-deployment-alpha.yaml --record
	@kubectl create -f kubernetes/$(NAME)-deployment-beta.yaml --record

kube-delete:
	@kubectl delete svc $(NAME)-alpha
	@kubectl delete svc $(NAME)-beta
	@kubectl delete deployment/$(NAME)-alpha
	@kubectl delete deployment/$(NAME)-beta
