#!/usr/bin/env bash

handle_error() {
  echo -e "\nError: $1\n"
  exit 1
}

mint_id_token() {
  username=$1
  password=$2
  client_id=$3
  client_secret=$4

  response=$(curl -s --request POST \
    --url 'https://amapiano-idp.us.auth0.com/oauth/token' \
    --header 'content-type: application/x-www-form-urlencoded' \
    --data grant_type=password \
    --data "username=${username}" \
    --data "password=${password}" \
    --data scope='openid email' \
    --data "client_id=${client_id}" \
    --data "client_secret=${client_secret}")

  if [ $? -ne 0 ]; then
    handle_error "Failed to mint OIDC id_token"
  fi

  id_token=$(echo "${response}" | jq -r .id_token)

  if [ -z "${id_token}" ]; then
    handle_error "Failed to extract id_token from response"
  fi

  echo "${id_token}"
}

configure_kubectl() {
  id_token=$1
  client_id=$2

  kubectl config set-credentials demo --auth-provider=oidc \
    --auth-provider-arg=idp-issuer-url=https://amapiano-idp.us.auth0.com/ \
    --auth-provider-arg=client-id="${client_id}" \
    --auth-provider-arg=id-token="${id_token}"

  if [ $? -ne 0 ]; then
    handle_error "Failed to configure kubectl with OIDC authentication"
  fi
}

authorize_user() {
  username=$1

  kubectl create clusterrolebinding demo-oidc-cluster-admin --clusterrole=cluster-admin --user="${username}"

  if [ $? -ne 0 ]; then
    handle_error "Failed to authorize user "${username}" with RBAC"
  fi
}

echo -e "Minting OIDC id_token by way of the OAUTH2 Resource Owner Password Grant type.\n"

username="demo@runtime.diaz"
password="Demo12345"
client_id="jLe7RD4MqaW6fFgRwOXa8B0n3OVFt4Z7"
client_secret="BCSXWL1IrhHz2WgqT1FLGpAxa6QNRL-6He5IJgSLxP65uV1PAcccjx_5knRGFTLH"

id_token=$(mint_id_token "${username}" "${password}" "${client_id}" "${client_secret}")

echo -e "Adding the id_token and authentication provider configuration to kubectl's kubeconfig.\n"

configure_kubectl "${id_token}" "${client_id}"

echo -e "\nAuthorizing the demo user by binding RBAC.\n"

authorize_user "${username}"

echo -e "\nValidate you have access to the cluster API by running the following commands.\n"
echo "kubectl --user=demo auth whoami"
echo "kubectl --user=demo get nodes"

chmod +x k8s_user_auth_init.sh