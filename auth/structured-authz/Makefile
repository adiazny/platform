SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := kindest/node:v1.31.2
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

PWD=$(shell pwd)

kind:
	@pwd=${PWD} envsubst < $(SINGLE_NODE_KIND_CONFIG) | kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config -
	@kubectl create namespace opa
	@kubectl apply -k .
	kubectl wait -n opa --for=condition=available --timeout=120s deployment/opa
	@kubectl create ns production
	@kubectl -n production run nginx-workload --image=nginx
	@echo "Cluster is ready"

create-%:
	@kind create cluster --name $(NAME) --wait $(WAIT)
   
delete-%:
	@kind delete cluster --name $(NAME)

clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

list:
	@kind get clusters

.PHONY: kind create-% delete-% clean list