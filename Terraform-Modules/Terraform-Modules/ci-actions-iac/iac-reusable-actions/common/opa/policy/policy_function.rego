package tfanalysis

import future.keywords.if
import future.keywords.in
import input as tfplan

# Array of all terraform resource types to analyze from plan doc
resource_type_list := get_resource_type_list

# Rule 1: Mandatory tags are required in relevant resources.
# This rule ensures that all mandatory tags are tagged
# in all listed resources.
mandatory_tags_missing_no_gtio = out if {
	# Obtains map of mandatory keys
	# Key: Tag Name
	# Value: Object consistenting of regex, and if applicable, gtio.
	# If no regex is required, then regex val is an empty string

	out := {error_val |
		# Obtain relevent resources from terra form plan.
		# Store tag map in r_tags
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType(r_type)
		r_obj := r_objects[_]
		r_tags := r_obj.tags
		r_obj_type := r_obj.type
		target_tags = get_consolidated_mandatory_tags_by_resourceType(r_obj_type)

		# Validate mandatory tags
		some i, val in target_tags
		tag_name := i
		not r_tags[tag_name]

		not val.gtio
		error_val := object.union(r_obj, {"missing_tag": tag_name})
	}
}

name_following_naming_convention = out if {

	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType(r_type)
		r_obj := r_objects[_]
		r_name := r_obj.name
		r_obj_type := r_obj.type

		name_regex := get_name_convention_by_resourceType(r_obj_type)
		not regex.match(name_regex, r_name)

		error_val := object.union(r_obj, {"name_breaking_convention": r_name, "regex": name_regex})
	}
}

using_right_module_root = out if {

	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType_with_root_module(r_type)
		r_obj := r_objects[_]
		r_source := r_obj.source
		r_obj_type := r_obj.type

		acceptable_sources := get_acceptable_sources(r_obj_type)
		not using_right_source(acceptable_sources, r_source)
		error_val := object.union(r_obj, {"bad_source": r_source, "acceptable_sources": acceptable_sources})
	}
}

using_right_module_nonroot = out if {

	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType_with_nonroot_module(r_type)
		r_obj := r_objects[_]
		r_source := r_obj.source
		r_obj_type := r_obj.type

		r_parent_modules := r_obj.parent_modules
		acceptable_sources := get_acceptable_sources(r_obj_type)
		not using_right_source(acceptable_sources, r_source)
		parent_acceptable := intersect(acceptable_sources, r_parent_modules)
		count(parent_acceptable) == 0
		
		error_val := object.union(r_obj, {"bad_source": r_source, "acceptable_sources": acceptable_sources})
	}
}

# Rule 2: Mandatory tags are valid in relevant resources.
# This rule ensures that all mandatory tags are properly validated
# with corresponding regex.
mandatory_tags_invalid_no_gtio = out if {
	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType(r_type)
		r_obj := r_objects[_]
		r_tags := r_obj.tags
		r_obj_type := r_obj.type
		target_tags = get_consolidated_mandatory_tags_by_resourceType(r_obj_type)

		some i, val in target_tags
		tag_name := i

		tag_regex := val.regex
		tag_value := r_tags[tag_name]

		not regex.match(tag_regex, tag_value)
		not val.gtio
		error_val := object.union(r_obj, {"missing_tag": tag_name, "regex": tag_regex})
	}
}

# Rule 3: Mandatory tags with a GTIO alternative
# is required in relevant resources.
# This rule ensures that tags that have a GTIO
# alternative are coreectly provided.
mandatory_tags_missing_gtio_missing = out if {
	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType(r_type)
		r_obj := r_objects[_]
		r_tags := r_obj.tags
		r_obj_type := r_obj.type
		target_tags = get_consolidated_mandatory_tags_by_resourceType(r_obj_type)
		some i, val in target_tags
		tag_name := i
		not r_tags[tag_name]
		gtio_tag_name := val.gtio
		not r_tags[gtio_tag_name]
		alias := val.alias
		intersection := intersect(alias, r_tags)
		count(intersection) == 0
		error_val := object.union(r_obj, {"missing_tag": tag_name, "gtio_tag_name": gtio_tag_name})
	}
}

# Rule 4: Mandatory tags with a GTIO alternative
# is valoid in relevant resources.
# This rule ensures that tags that have a GTIO
# alternative are properly validated
mandatory_tags_missing_gtio_invalid = out if {
	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType(r_type)
		r_obj := r_objects[_]
		r_tags := r_obj.tags
		r_obj_type := r_obj.type
		target_tags = get_consolidated_mandatory_tags_by_resourceType(r_obj_type)

		some i, val in target_tags
		tag_name := i
		not r_tags[tag_name]
		tag_regex := val.regex
		alias := val.alias
		intersection := intersect(alias, r_tags)
		count(intersection) == 0
		gtio_tag_name := val.gtio

		gtio_tag_value := r_tags[gtio_tag_name]
		not regex.match(tag_regex, gtio_tag_value)
		error_val := object.union(r_obj, {"missing_tag": tag_name, "gtio_tag_name": gtio_tag_name, "regex": tag_regex})
	}
}

# Rule 5: Optional tags with no GTIO alternative
# is valid in relevant resources.
# This rule ensures that optional tags
# with no GTIO alternative have the
# proper regex validation.
optional_tags_invalid_no_gtio = out if {
	out := {error_val |
		r_type := resource_type_list[_]
		r_objects := get_resource_by_resourceType(r_type)
		r_obj := r_objects[_]
		r_tags := r_obj.tags
		r_obj_type := r_obj.type
		target_tags = get_consolidated_optional_tags_by_resourceType(r_obj_type)

		some i, val in target_tags
		tag_name := i
		tag_regex := val.regex

		tag_value := r_tags[tag_name]
		not regex.match(tag_regex, tag_value)
		not val.gtio
		error_val := object.union(r_obj, {"invalid_tag": tag_name, "regex": tag_regex})
	}
}

## Cloud Storage Logging Policy
cloud_storage_logging_enabled = out if {
	out := {error_val |
		r_objects := get_full_resource_by_resourceType("google_storage_bucket")
		r_obj := r_objects[_]
		not r_obj.change.after.logging == true
		error_val := object.union(r_obj, {"invalid_obj": r_obj.name})
	}
}

## Cloud Storage Versioning Policy
cloud_storage_versioning_enabled = out if {
	out := {error_val |
		r_objects := get_full_resource_by_resourceType("google_storage_bucket")
		r_obj := r_objects[_]
		some i
		versioning := r_obj.change.after.versioning[i]
		not r_obj.change.after.versioning[i].enabled == true
		error_val := object.union(r_obj, {"invalid_obj": r_obj.name})
	}
}

## Cloud Storage Uniform bucket access Policy
cloud_storage_uniform_bucket_access = out if {
	out := {error_val |
		r_objects := get_full_resource_by_resourceType("google_storage_bucket")
		r_obj := r_objects[_]
		not r_obj.change.after.uniform_bucket_level_access == true
		error_val := object.union(r_obj, {"invalid_obj": r_obj.name})
	}
}
