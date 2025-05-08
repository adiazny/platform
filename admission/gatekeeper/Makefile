SHELL_PATH := /bin/bash

.DEFAULT_GOAL := help

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := 1.32.3
KIND_IMAGE := kindest/node:v${KIND_NODE_VERSION}
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

GATEKEEPER_VERSION := 3-18-3

PWD=$(shell pwd)

.PHONY: help
help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z0-9_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-30s %s\n", $$1, $$2}'

.PHONY: kind
kind: ## Create a single-node kind cluster named dolo01
	@pwd=${PWD} envsubst < $(SINGLE_NODE_KIND_CONFIG) | kind create cluster --name dolo01 --image $(KIND_IMAGE) --config -
	@echo "Cluster is ready"

.PHONY: create-%
create-%: ## Create a kind cluster with specified name (usage: make create-<cluster-name>)
	@kind create cluster --name $(NAME) --image $(KIND_IMAGE) --wait $(WAIT)

.PHONY: delete-%
delete-%: ## Delete a kind cluster with specified name (usage: make delete-<cluster-name>)
	@kind delete cluster --name $(NAME)

.PHONY: clean
clean: ## Delete all kind clusters
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

.PHONY: list
list: ## List all kind clusters
	@kind get clusters

.PHONY: deploy-gk-3-15-1
deploy-gk-3-15-1: ## Deploy Gatekeeper version 3.15.1
	@echo "Deploying Gatekeeper 3.15.1..."
	@./deployment/deploy.sh 3-15-1

.PHONY: deploy-gk-3-18-3
deploy-gk-3-18-3: ## Deploy Gatekeeper version 3.18.3
	@echo "Deploying Gatekeeper 3.18.3..."
	@./deployment/deploy.sh 3-18-3

.PHONY: apply-mutation-policy
apply-mutation-policy: ## Apply Gatekeeper mutation policies
	@echo "Applying mutation policies..."
	@$(APPLY) policy/mutation/assign-allow-privilege-escalation.yaml

.PHONY: apply-validation-policy
apply-validation-policy: ## Apply Gatekeeper validation policies
	@echo "Applying validation policies..."
	@$(APPLY) policy/validation/block-node-port-constraint-template.yaml
	@$(APPLY) policy/validation/block-node-port-constraint.yaml

.PHONY: apply-policy
apply-policy: ## Apply all Gatekeeper mutation and validation policies
	@echo "Applying all Gatekeeper mutation and validation policies..."
	@$(MAKE) --no-print-directory apply-mutation-policy
	@$(MAKE) --no-print-directory apply-validation-policy

.PHONY: apply-pod
apply-pod: ## Apply example pod for mutation testing
	@echo "Applying a example pod to be mutated..."
	@$(APPLY) policy/mutation/example/pod.yaml

.PHONY: apply-allowed-service
apply-allowed-service: ## Apply an allowed Service example
	@echo "Applying an allowed Service creation..."
	@$(APPLY) policy/validation/examples/allow.yaml

.PHONY: apply-disallowed-service
apply-disallowed-service: ## Apply a blocked Service example (expected to fail)
	@echo "Applying a blocked Service creation..."
	@echo "This apply is expected to fail"
	@$(APPLY) policy/validation/examples/disallow.yaml || true

.PHONY: apply-example-resources
apply-example-resources: ## Apply all example resources (pod and services)
	@$(MAKE) --no-print-directory apply-pod
	@$(MAKE) --no-print-directory apply-allowed-service
	@$(MAKE) --no-print-directory apply-disallowed-service

.PHONY: cleanup
cleanup: ## Clean up all Gatekeeper resources
	@echo "Cleaning up Gatekeeper resources..."
	@./deployment/deploy.sh cleanup $(GATEKEEPER_VERSION)
