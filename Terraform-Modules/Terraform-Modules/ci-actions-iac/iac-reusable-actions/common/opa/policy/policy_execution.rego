package tfanalysis

import future.keywords.in
import data.name_config as name_config

# This function evaluates all critical rules defined in policy_function.rego.
# Each rule is evaluated then formated with a relevant error messge.
# The error message(s) are then compiled into an array.
# The arrays for each rule are then merged into output.
critical = output {
	mandatory_tags_missing_no_gtio_obj := mandatory_tags_missing_no_gtio
	mandatory_tags_missing_no_gtio_errors := {msg |
		error_obj := mandatory_tags_missing_no_gtio_obj[_]
		missing_tag_name := error_obj.missing_tag
		address := error_obj.address
		msg := sprintf("Missing required tag '%s' for resource %s.", [missing_tag_name, address])
	}

	name_following_naming_convention_obj := name_following_naming_convention
	name_following_naming_convention_errors := {msg |
		error_obj := name_following_naming_convention_obj[_]
		breaking_name := error_obj.name_breaking_convention
		address := error_obj.address
		regex := error_obj.regex
		msg := sprintf("Name breaking convention '%s' for resource %s. Must follow this pattern: ", [breaking_name, address, regex])
	}

	using_right_module_root_obj := using_right_module_root
	using_right_module_root_errors := {msg |
		error_obj := using_right_module_root_obj[_]
		breaking_source := error_obj.bad_source
		address := error_obj.address
		acceptable_sources := error_obj.acceptable_sources
		msg := sprintf("Using unapproved module '%s' to create resource %s. Must use one of the following modules: ", [breaking_source, address, acceptable_sources])
	}

	using_right_module_nonroot_obj := using_right_module_nonroot
	using_right_module_nonroot_errors := {msg |
		error_obj := using_right_module_nonroot_obj[_]
		breaking_source := error_obj.bad_source
		address := error_obj.address
		acceptable_sources := error_obj.acceptable_sources
		msg := sprintf("Using unapproved module '%s' to create resource %s. Must use one of the following modules: ", [breaking_source, address, acceptable_sources])
	}

	mandatory_tags_invalid_no_gtio_obj := mandatory_tags_invalid_no_gtio
	mandatory_tags_invalid_no_gtio_errors := {msg |
		error_obj := mandatory_tags_invalid_no_gtio_obj[_]
		missing_tag_name := error_obj.missing_tag
		address := error_obj.address
		regex := error_obj.regex
		msg := sprintf("Invalid tag '%s' for resource %s. Expected regex: %s", [missing_tag_name, address, regex])
	}

	mandatory_tags_missing_gtio_missing_obj := mandatory_tags_missing_gtio_missing
	mandatory_tags_missing_gtio_missing_errors := {msg |
		error_obj := mandatory_tags_missing_gtio_missing_obj[_]
		missing_tag_name := error_obj.missing_tag
		address := error_obj.address
		gtio_tag_name := error_obj.gtio_tag_name
		msg := sprintf("Missing required tag '%s' or '%s' for resource %s", [missing_tag_name, gtio_tag_name, address])
	}

	mandatory_tags_missing_gtio_invalid_obj := mandatory_tags_missing_gtio_invalid
	mandatory_tags_missing_gtio_invalid_errors := {msg |
		error_obj := mandatory_tags_missing_gtio_invalid_obj[_]
		missing_tag_name := error_obj.missing_tag
		address := error_obj.address
		gtio_tag_name := error_obj.gtio_tag_name
		regex := error_obj.regex
		msg := sprintf("Invalid tag '%s' or '%s' for resource %s. Valid regex is: %s", [missing_tag_name, gtio_tag_name, address, regex])
	}

	cloud_storage_logging_enabled_obj := cloud_storage_logging_enabled
	cloud_storage_logging_enabled_errors := {msg |
		error_obj := cloud_storage_logging_enabled_obj[_]
		invalid_obj_name := error_obj.invalid_obj
		msg := sprintf("Logging not enabled for cloud storage bucket '%s'", [invalid_obj_name])
	}

	cloud_storage_versioning_enabled_obj := cloud_storage_versioning_enabled
	cloud_storage_versioning_enabled_errors := {msg |
		error_obj := cloud_storage_versioning_enabled_obj[_]
		invalid_obj_name := error_obj.invalid_obj
		msg := sprintf("Versioning not enabled for cloud storage bucket '%s'", [invalid_obj_name])
	}

	cloud_storage_uniform_bucket_access_obj := cloud_storage_uniform_bucket_access
	cloud_storage_uniform_bucket_access_errors := {msg |
		error_obj := cloud_storage_uniform_bucket_access_obj[_]
		invalid_obj_name := error_obj.invalid_obj
		msg := sprintf("Uniform Bucket access not enabled for cloud storage bucket '%s'", [invalid_obj_name])
	}

	output := ((mandatory_tags_missing_no_gtio_errors | mandatory_tags_invalid_no_gtio_errors) | mandatory_tags_missing_gtio_missing_errors) | mandatory_tags_missing_gtio_invalid_errors | name_following_naming_convention_errors | using_right_module_root_errors | using_right_module_nonroot_errors | cloud_storage_logging_enabled_errors | cloud_storage_uniform_bucket_access_errors | cloud_storage_versioning_enabled_errors
}

# This function evaluates all warning rules defined in policy_function.rego.
# Each rule is evaluated then formated with a relevant error messge.
# The error message(s) are then compiled into an array.
# The arrays for each rule are then merged into output.
warning = output {
	optional_tags_invalid_no_gtio_obj := optional_tags_invalid_no_gtio
	optional_tags_invalid_no_gtio_errors := {msg |
		error_obj := optional_tags_invalid_no_gtio_obj[_]
		invalid_tag_name := error_obj.invalid_tag
		address := error_obj.address
		regex := error_obj.regex
		msg := sprintf("Invalid tag '%s' for resource %s. Valid regex is: %s", [invalid_tag_name, address, regex])
	}

	output := optional_tags_invalid_no_gtio_errors
}

# This rule is used to determine the breaking condition of the full evaluation of
# the terraform plan input. If there are no critical errors "set() == empty set",
# then the evalutation passes. Otherwise, the evaluation fails.
evaluate {
	critical == set()
}
