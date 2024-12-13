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
  scope=$6

  response=$(curl -s --request POST \
    --url ${oauth_token_url} \
    --header 'content-type: application/x-www-form-urlencoded' \
    --data grant_type=password \
    --data "username=${username}" \
    --data "password=${password}" \
    --data scope="${scope}" \
    --data "client_id=${client_id}" \
    --data "client_secret=${client_secret}")

  if [ $? -ne 0 ]; then
    handle_error "Failed to mint OIDC id_token"
  fi

  if echo "${response}" | grep -i "error"; then
    handle_error "${response}"
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

  if kubectl get clusterrolebinding | grep -q "${user}"-oidc-cluster-admin; then
    echo -e "\nDeleting previous clusterrolebinding for user ${user}"
    kubectl delete clusterrolebinding "${user}"-oidc-cluster-admin
  fi

  group=$(kubectl --user="${username}" auth whoami -o json | jq -r '.status.userInfo.groups[] | select(startswith("system") | not)')

  kubectl create clusterrolebinding "${user}"-oidc-cluster-admin --clusterrole=cluster-admin --group="${group}"

  if [ $? -ne 0 ]; then
    handle_error "Failed to authorize user "${username}" with RBAC"
  fi
}

add_user_to_kubeconfig() {
  oauth_token_url=$1
  idp_issuer_url=$2
  username=$3
  password=$4
  client_id=$5
  client_secret=$6
  scope=$7

  id_token=$(
    mint_id_token \
      "${oauth_token_url}" \
      "${username}" \
      "${password}" \
      "${client_id}" \
      "${client_secret}" \
      "${scope}"
  )

  echo -e "id_token: ${id_token}\n"

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

while [[ $# -gt 0 ]]; do
  case $1 in
    --oauth-token-url)
      OAUTH_TOKEN_URL="$2"
      shift 2
      ;;
    --idp-issuer-url)
      IDP_ISSUER_URL="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    --client-id)
      CLIENT_ID="$2"
      shift 2
      ;;
    --client-secret)
      CLIENT_SECRET="$2"
      shift 2
      ;;
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1"
      exit 1
      ;;
  esac
done

if [ -z "${OAUTH_TOKEN_URL}" ] || [ -z "${IDP_ISSUER_URL}" ] || [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ] || [ -z "${CLIENT_ID}" ] || [ -z "${CLIENT_SECRET}" ] || [ -z "${SCOPE}" ]; then
  echo "All flags must be provided"
  exit 1
fi

add_user_to_kubeconfig \
  "${OAUTH_TOKEN_URL}" \
  "${IDP_ISSUER_URL}" \
  "${USERNAME}" \
  "${PASSWORD}" \
  "${CLIENT_ID}" \
  "${CLIENT_SECRET}" \
  "${SCOPE:-"openid email"}"