package tfanalysis

import future.keywords.in
import input as tfplan
import data.tag_config as tag_config

# This function returns a set of objects, each corresponding
# to a resource that matches the specified resourceType in the
# input Terraform plan.
# Each object in the set contains the following properties:
#     "address" - The unique address of the resource in the
#           Terraform plan.
#     "type" - The type of the resource (matching the
#           input resourceType).
#     "actions" - A list of actions (like 'create',
#           'update', 'delete') that are to be performed on the resource.
#     "tags" - A key-value map representing
#           the final state of the resource's tags after the plan is executed.

get_resource_by_resourceType(resourceType) = output {
	output := {x |
		some i
		regex.match(resourceType, tfplan.resource_changes[i].type)
		x := {
			"address": input.resource_changes[i].address,
			"type": input.resource_changes[i].type,
			"name": input.resource_changes[i].name,
			"actions": input.resource_changes[i].change.actions,
			"tags": get_tags(resourceType, input.resource_changes[i].change),
		}
	}
}

get_full_resource_by_resourceType(resourceType) = output {
	output := { x |
		some i
		regex.match(resourceType, tfplan.resource_changes[i].type)
		x := input.resource_changes[i]
	}
}

get_resource_by_resourceType_with_root_module(r_type) = output {
	output := {x |
		some i
		regex.match(r_type, tfplan.configuration.root_module.resources[i].type)
		x := {
			"address": tfplan.configuration.root_module.resources[i].address,
			"type": tfplan.configuration.root_module.resources[i].type,
			"name": tfplan.configuration.root_module.resources[i].name,
			"source": "root_module"
		}
	}
}

get_resource_by_resourceType_with_nonroot_module(r_type) = output {
	output := {x |
		some key
		module_val := tfplan.configuration.root_module.module_calls[key]
		some i
		regex.match(r_type, module_val.module.resources[i].type)
		x := {
			"address": module_val.module.resources[i].address,
			"type": module_val.module.resources[i].type,
			"name": module_val.module.resources[i].name,
			"source": module_val.source,
			"parent_modules": module_val.parent_modules
		}
	}
}

# This function returns tags from resource tags section or from helm release set based on the resource type
get_tags(r_type, doc) = out {
	not r_type == "helm_release"
	not tag_config.infra_list.gcp[r_type]
	out := doc.after.tags
}
	else = out {
	out := doc.after.labels
}
	else = out {
	out := convert_to_json(get_helmSet_value_for_given_name(doc.after.set, "envVars"))
}

# This function converts tag format from helm release set to tags json
convert_to_json(tags) = out {
	parts := split(tags, ";")
	out := {k: v |
		pair := parts[_]
		k := trim(split(pair, ":")[0], " ")
		v := trim(split(pair, ":")[1], " ")
	}
}

# This function filters the envVars set
get_helmSet_value_for_given_name(helm_set, name) = value {
	some i
	helm_set[i].name == name
	value := helm_set[i].value
}

