#!/usr/bin/env bash

./k8s_user_auth_init.sh \
  --oauth-token-url "https://amapiano-idp.us.auth0.com/oauth/token" \
  --idp-issuer-url "https://amapiano-idp.us.auth0.com/" \
  --username "jonny@runtime.diaz" \
  --password "Demo12345" \
  --client-id "jLe7RD4MqaW6fFgRwOXa8B0n3OVFt4Z7" \
  --client-secret "BCSXWL1IrhHz2WgqT1FLGpAxa6QNRL-6He5IJgSLxP65uV1PAcccjx_5knRGFTLH" \
  --scope "openid email role:edit S12345"