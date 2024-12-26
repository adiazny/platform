SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := kindest/node:v1.31.2
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

PWD=$(shell pwd)

single-node-cluster:
	@pwd=${PWD} envsubst < $(SINGLE_NODE_KIND_CONFIG) | kind create cluster --name dolo01 --image $(KIND_NODE_VERSION) --config -
	@kubectl create namespace opa
	@kubectl apply -k .
	@kubectl create clusterrolebinding someuser --clusterrole=cluster-admin --user=someuser
	@kubectl wait --for=jsonpath='{.status.currentNumberScheduled}'='1' --timeout=120s daemonset/opa -n opa
	@echo "Cluster is ready"
	#@docker exec dolo01-control-plane /bin/bash -c "sed -i '/--authorization-mode=Node,RBAC/ s/Node,RBAC/Node,Webhook,RBAC/; /--authorization-mode=Node,Webhook,RBAC/ a\    - --authorization-webhook-version=v1\n    - --authorization-webhook-config-file=/etc/kubernetes/api-server/authz-webhook-kubeconfig.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml"

create-%:
	@kind create cluster --name $(NAME) --wait $(WAIT)
   
delete-%:
	@kind delete cluster --name $(NAME)

clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

list:
	@kind get clusters

.PHONY: single-node-cluster create-% delete-% clean list