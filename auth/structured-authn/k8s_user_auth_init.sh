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
  audience=$6
  scope=$7

  response=$(curl -s --request POST \
    --url ${oauth_token_url} \
    --header 'content-type: application/x-www-form-urlencoded' \
    --data grant_type=password \
    --data "username=${username}" \
    --data "password=${password}" \
    --data scope="${scope}" \
    --data "client_id=${client_id}" \
    --data "client_secret=${client_secret}" \
    --data "audience=${audience}")

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

add_user_to_kubeconfig() {
  oauth_token_url=$1
  idp_issuer_url=$2
  username=$3
  password=$4
  client_id=$5
  client_secret=$6
  audience=$7

  id_token=$(
    mint_id_token \
      "${oauth_token_url}" \
      "${username}" \
      "${password}" \
      "${client_id}" \
      "${client_secret}" \
      "${audience}"
  )

  echo -e "${id_token}\n"

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
}


# AMAPIANO IDP USER
amapiano_oauth_token_url="https://amapiano-idp.us.auth0.com/oauth/token"
amapiano_idp_issuer_url="https://amapiano-idp.us.auth0.com/"
amapiano_username="jonny@runtime.diaz"
amapiano_password="Demo12345"
amapiano_client_id="jLe7RD4MqaW6fFgRwOXa8B0n3OVFt4Z7"
amapiano_client_secret="BCSXWL1IrhHz2WgqT1FLGpAxa6QNRL-6He5IJgSLxP65uV1PAcccjx_5knRGFTLH"
amapiano_audience="https://amapiano-idp.us.auth0.com/api/v2/"

add_user_to_kubeconfig \
  "${amapiano_oauth_token_url}" \
  "${amapiano_idp_issuer_url}" \
  "${amapiano_username}" \
  "${amapiano_password}" \
  "${amapiano_client_id}" \
  "${amapiano_client_secret}" \
  "${amapiano_audience}"

# SALSA IDP USER
salsa_oauth_token_url="https://salsa-idp.us.auth0.com/oauth/token"
salsa_idp_issuer_url="https://salsa-idp.us.auth0.com/"
salsa_username="foo@salsa.dev"
salsa_password="Foo12345"
salsa_client_id="u2vEGqwWnlf2QtXu56dhWOCwydMtY2n5"
salsa_client_secret="_l4GmT25-rV21wNoD_gcxXgm42C1ZWbtvZXUykIjoEyNypUeCIq9B2pTzHwUy5no"
salsa_audience="https://salsa-idp.us.auth0.com/api/v2/"

add_user_to_kubeconfig \
  "${salsa_oauth_token_url}" \
  "${salsa_idp_issuer_url}" \
  "${salsa_username}" \
  "${salsa_password}" \
  "${salsa_client_id}" \
  "${salsa_client_secret}" \
  "${salsa_audience}"

chmod +x k8s_user_auth_init.sh