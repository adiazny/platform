#!/usr/bin/env bash

handle_error() {
  echo -e "\nError: $1\n"
  exit 1
}

mint_id_token() {
  oauth_token_url=$1
  username=$2
  password=$3
  client_id=$4
  client_secret=$5

  response=$(curl -s --request POST \
    --url ${oauth_token_url} \
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
  username=$1
  idp_issuer_url=$2
  id_token=$3
  client_id=$4

  kubectl config set-credentials ${username} --auth-provider=oidc \
    --auth-provider-arg=idp-issuer-url=${idp_issuer_url} \
    --auth-provider-arg=client-id="${client_id}" \
    --auth-provider-arg=id-token="${id_token}"

  if [ $? -ne 0 ]; then
    handle_error "Failed to configure kubectl with OIDC authentication"
  fi
}

authorize_user() {
  username=$1
  user=${username/%@*/}

  kubectl create clusterrolebinding ${user}-oidc-cluster-admin --clusterrole=cluster-admin --user="${username}"

  if [ $? -ne 0 ]; then
    handle_error "Failed to authorize user "${email}" with RBAC"
  fi
}

echo -e "Minting OIDC id_token by way of the OAUTH2 Resource Owner Password Grant type.\n"

# AMAPIANO USER
oauth_token_url="https://amapiano-idp.us.auth0.com/oauth/token"
idp_issuer_url="https://amapiano-idp.us.auth0.com/"
username="demo@runtime.diaz"
password="Demo12345"
client_id="jLe7RD4MqaW6fFgRwOXa8B0n3OVFt4Z7"
client_secret="BCSXWL1IrhHz2WgqT1FLGpAxa6QNRL-6He5IJgSLxP65uV1PAcccjx_5knRGFTLH"

id_token=$(mint_id_token "${oauth_token_url}" "${username}" "${password}" "${client_id}" "${client_secret}")

echo "${id_token}"

if [ -z "${id_token}" ]; then
  handle_error "id_token is empty. Check your Auth0 configuration."
fi

echo -e "Adding the id_token and authentication provider configuration to kubectl's kubeconfig.\n"

configure_kubectl "${username}" "${idp_issuer_url}" "${id_token}" "${client_id}"

echo -e "\nAuthorizing the demo user by binding RBAC.\n"

authorize_user "${username}"

echo -e "\nValidate you have access to the cluster API by running the following commands.\n"
echo "kubectl --user=${username} auth whoami"
echo "kubectl --user=${username} get nodes"

chmod +x k8s_user_auth_init.sh