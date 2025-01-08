SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := kindest/node:v1.32.0
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

PWD=$(shell pwd)

.PHONY: kind
kind:
	@pwd=${PWD} envsubst < $(SINGLE_NODE_KIND_CONFIG) | kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config -
	@echo "Cluster is ready"

.PHONY: create-%
create-%:
	@kind create cluster --name $(NAME) --wait $(WAIT)

.PHONY: delete-%
delete-%:
	@kind delete cluster --name $(NAME)

.PHONY: clean
clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

.PHONY: list
list:
	@kind get clusters