#!/bin/bash
set -euo pipefail

DEFAULT_GATEKEEPER_VERSION="3-18-3"

if [[ "${1:-}" == "cleanup" ]]; then
  GATEKEEPER_VERSION="${2:-$DEFAULT_GATEKEEPER_VERSION}"
  echo "Cleaning up Gatekeeper and cert-manager resources for version $GATEKEEPER_VERSION..."

  echo "Deleting Validating Gatekeeper..."
  kubectl delete -f deployment/validating-gatekeeper-${GATEKEEPER_VERSION}.yaml --ignore-not-found

  echo "Deleting Mutating Gatekeeper..."
  kubectl delete -f deployment/mutating-gatekeeper-${GATEKEEPER_VERSION}.yaml --ignore-not-found

  echo "Deleting cert-manager resources..."
  kubectl delete -f deployment/cert-manager-resources.yaml --ignore-not-found

  echo "Deleting cert-manager..."
  kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml --ignore-not-found

  echo "Deleting namespace gatekeeper-system..."
  kubectl delete namespace gatekeeper-system --ignore-not-found

  echo "Cleanup complete!"
  exit 0
fi

GATEKEEPER_VERSION="${1:-$DEFAULT_GATEKEEPER_VERSION}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    admission.gatekeeper.sh/ignore: no-self-managing
    gatekeeper.sh/system: "yes"
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: v1.24
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
  name: gatekeeper-system
EOF

echo "Installing Gatekeeper version: $GATEKEEPER_VERSION"


CERT_MANAGER_VERSION="1.17.2"
echo "Installing cert-manager version: $CERT_MANAGER_VERSION"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.yaml

echo "Waiting 60 seconds for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=60s

echo "Applying cert-manager resources..."
kubectl apply -f deployment/cert-manager-resources.yaml

echo "Waiting 30 seconds for Certificate to be ready..."
kubectl wait --for=condition=ready certificate gatekeeper-mutating-webhook-cert -n gatekeeper-system --timeout=30s

echo "Deploying Mutating Gatekeeper..."
kubectl apply -f deployment/mutating-gatekeeper-${GATEKEEPER_VERSION}.yaml

echo "Waiting 30 seconds for Mutating Gatekeeper Webhook to be ready..."
kubectl wait --for=condition=ready pod -l gatekeeper.sh/operation=mutating-webhook -n gatekeeper-system --timeout=30s

echo "Deployment complete! Verifying setup..."
echo "Checking Certificate status:"
kubectl get certificate -n gatekeeper-system gatekeeper-mutating-webhook-cert

echo "Checking Secret status:"
kubectl get secret -n gatekeeper-system gatekeeper-mutating-webhook-server-cert

echo "Checking MutatingWebhookConfiguration:"
kubectl get mutatingwebhookconfigurations gatekeeper-mutating-webhook-configuration

echo "Deploying Validating Gatekeeper..."
kubectl apply -f deployment/validating-gatekeeper-${GATEKEEPER_VERSION}.yaml

echo "Waiting 30 seconds for Validating Gatekeeper Webhook to be ready..."
kubectl wait --for=condition=ready pod -l gatekeeper.sh/operation=webhook -n gatekeeper-system --timeout=30s

echo "Checking ValidatingWebhookConfiguration:"
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration