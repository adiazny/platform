SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := kindest/node:v1.31.2
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

single-node-cluster:
	@kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config $(SINGLE_NODE_KIND_CONFIG)

create-%:
	@kind create cluster --name $(NAME) --wait $(WAIT)
   
delete-%:
	@kind delete cluster --name $(NAME)

clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

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