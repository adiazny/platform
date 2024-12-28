package k8s.authz

import rego.v1


deny contains reason if {
	input.spec.resourceAttributes.namespace == "production"

	required_groups := {"system:authenticated", "jit-edit"}
	provided_groups := {group | some group in input.spec.groups}

	count(required_groups & provided_groups) != count(required_groups)

	reason := sprintf("OPA: provided groups (%v) does not include all required groups: (%v)", [
		concat(", ", provided_groups),
		concat(", ", required_groups),
	])
}

decision := {
	"apiVersion": input.apiVersion,
	"kind": "SubjectAccessReview",
	"status": {
		"denied": count(deny) >= 1,
		"allowed": count(deny) == 0,
		"reason": concat(" | ", deny),
	},
}