package system

import rego.v1

main := {
	"apiVersion": input.apiVersion,
	"kind": "SubjectAccessReview",
	"status": {
		"denied": deny,
		"allowed": allow,
		"reason": reason,
	},
}

default allow := false

allow if {
	some group in input.spec.groups
	group == "role:deployer"
}

default deny := false

default reason := "simply observing"

reason := "allowed by custom webhook" if allow