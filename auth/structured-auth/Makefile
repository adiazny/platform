SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := kindest/node:v1.31.2
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

PWD=$(shell pwd)

.PHONY: kind
kind:
	@pwd=${PWD} envsubst < $(SINGLE_NODE_KIND_CONFIG) | kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config -
	@kubectl create namespace opa
	@kubectl apply -k .
	kubectl wait -n opa --for=condition=available --timeout=120s deployment/opa
	@kubectl create ns production
	@kubectl -n production run nginx-workload --image=nginx
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

.PHONY: workflow1
workflow1:
	@chmod +x k8s_user_auth_init.sh user-oauth-workflow-1.sh
	./user-oauth-workflow-1.sh

.PHONY: workflow2
workflow2:
	@chmod +x k8s_user_auth_init.sh user-oauth-workflow-2.sh
	./user-oauth-workflow-2.sh

.PHONY: single-node-cluster create-% delete-% clean list