SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := 1.32.3
KIND_IMAGE := kindest/node:v${KIND_NODE_VERSION}
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

PWD=$(shell pwd)

.PHONY: kind
kind:
	@pwd=${PWD} envsubst < $(SINGLE_NODE_KIND_CONFIG) | kind create cluster --name dolo01 --image $(KIND_IMAGE) --config -
	@echo "Cluster is ready"

.PHONY: create-%
create-%:
	@kind create cluster --name $(NAME) --image $(KIND_IMAGE) --wait $(WAIT)

.PHONY: delete-%
delete-%:
	@kind delete cluster --name $(NAME)

.PHONY: clean
clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

.PHONY: list
list:
	@kind get clusters