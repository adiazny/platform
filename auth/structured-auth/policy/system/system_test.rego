package system_test

import data.system

import rego.v1

mock_input := {
	"apiVersion": "authorization.k8s.io/v1",
	"kind": "SubjectAccessReview",
	"spec": {
		"resourceAttributes": {
			"verb": "create",
			"group": "apps",
			"version": "v1",
			"resource": "deployments",
			"namespace": "myapp-dev",
			"name": "my-deployment",
		},
		"user": "developer-user",
		"groups": [
			"developers",
			"authenticated",
		],
		"uid": "dev-user-12345",
		"extra": {
			"oauthID": ["dev-user-oauth-001"],
			"projectRoles": [
				"app-dev-lead",
				"ci-cd-manager",
			],
			"department": ["engineering"],
		},
	},
}

test_sar_response if {
	response := system.main with input as mock_input

	response.status.allowed == false
	response.status.denied == false
	response.status.reason == "simply observing"
}
