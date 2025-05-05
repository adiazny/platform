SHELL_PATH := /bin/bash

APPLY = kubectl apply --filename
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
WAIT := 200s

KIND_NODE_VERSION := 1.32.3
KIND_IMAGE := kindest/node:v${KIND_NODE_VERSION}
SINGLE_NODE_KIND_CONFIG := single-node-kind-config.yaml

GATEKEEPER_VERSION := 3-18-3

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

.PHONY: deploy-gk-3-15-1
deploy-gk-3-15-1:
	@echo "Deploying Gatekeeper 3.15.1..."
	@./deployment/deploy.sh 3-15-1

.PHONY: deploy-gk-3-18-3
deploy-gk-3-18-3:
	@echo "Deploying Gatekeeper 3.18.3..."
	@./deployment/deploy.sh 3-18-3

.PHONY: apply-mutation-policy
apply-mutation-policy:
	@echo "Applying mutation policies..."
	@$(APPLY) policy/mutation/assign-allow-privilege-escalation.yaml

.PHONY: apply-validation-policy
apply-validation-policy:
	@echo "Applying validation policies..."
	@$(APPLY) policy/validation/block-node-port-constraint-template.yaml
	@$(APPLY) policy/validation/block-node-port-constraint.yaml

.PHONY: apply-policy
apply-policy:
	@echo "Applying all Gatekeeper mutation and validation policies..."
	@$(MAKE) --no-print-directory apply-mutation-policy
	@$(MAKE) --no-print-directory apply-validation-policy

.PHONY: apply-pod
apply-pod:
	@echo "Applying a example pod to be mutated..."
	@$(APPLY) policy/mutation/example/pod.yaml

.PHONY: apply-allowed-service
apply-allowed-service:
	@echo "Applying an allowed Service creation..."
	@$(APPLY) policy/validation/examples/allow.yaml

.PHONY: apply-disallowed-service
apply-disallowed-service:
	@echo "Applying a blocked Service creation..."
	@echo "This apply is expected to fail"
	@$(APPLY) policy/validation/examples/disallow.yaml || true

apply-example-resources:
	@$(MAKE) --no-print-directory apply-pod
	@$(MAKE) --no-print-directory apply-allowed-service
	@$(MAKE) --no-print-directory apply-disallowed-service

.PHONY: cleanup
cleanup:
	@echo "Cleaning up Gatekeeper resources..."
	@./deployment/deploy.sh cleanup $(GATEKEEPER_VERSION)
