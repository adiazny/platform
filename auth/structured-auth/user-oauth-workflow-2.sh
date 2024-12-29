#!/usr/bin/env bash

./k8s_user_auth_init.sh \
  --oauth-token-url "https://salsa-idp.us.auth0.com/oauth/token" \
  --idp-issuer-url "https://salsa-idp.us.auth0.com/" \
  --username "jonny@runtime.diaz" \
  --password "Demo12345" \
  --client-id "u2vEGqwWnlf2QtXu56dhWOCwydMtY2n5" \
  --client-secret "_l4GmT25-rV21wNoD_gcxXgm42C1ZWbtvZXUykIjoEyNypUeCIq9B2pTzHwUy5no" \
  --scope "openid email"