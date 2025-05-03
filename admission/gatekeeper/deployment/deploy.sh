#!/bin/bash
set -euo pipefail

echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s

echo "Applying cert-manager resources..."
kubectl apply -f deployment/cert-manager-resources.yaml

echo "Waiting for Certificate to be ready..."
kubectl wait --for=condition=ready certificate gatekeeper-mutating-webhook-cert -n gatekeeper-system --timeout=60s

echo "Deploying Gatekeeper..."
kubectl apply -f deployment/mutating-gatekeeper-3-18-3.yaml

echo "Waiting for Gatekeeper to be ready..."
kubectl wait --for=condition=ready pod -l gatekeeper.sh/operation=mutating-webhook -n gatekeeper-system --timeout=120s

echo "Deployment complete! Verifying setup..."
echo "Checking Certificate status:"
kubectl get certificate -n gatekeeper-system gatekeeper-mutating-webhook-cert
echo "Checking Secret status:"
kubectl get secret -n gatekeeper-system gatekeeper-mutating-webhook-server-cert
echo "Checking MutatingWebhookConfiguration:"
kubectl get mutatingwebhookconfigurations gatekeeper-mutating-webhook-configuration
