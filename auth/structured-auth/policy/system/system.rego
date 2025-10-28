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

default deny := false

default reason := "simply observing"
