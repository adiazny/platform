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
	@kubectl create clusterrolebinding someuser --clusterrole=cluster-admin --user=someuser
	kubectl wait -n opa --for=condition=available --timeout=120s deployment/opa
	@kubectl create ns production
	@kubectl -n production run workload --image=nginx -- /bin/echo "Hello from production"
	@docker exec -it dolo01-control-plane /bin/bash -c "cp /etc/kubernetes/api-server/add-webhook-stanza.yaml /etc/kubernetes/api-server/structured-authz-config.yaml"
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