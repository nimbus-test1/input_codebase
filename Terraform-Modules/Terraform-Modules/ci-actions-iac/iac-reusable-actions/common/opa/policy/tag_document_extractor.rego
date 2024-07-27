package tfanalysis

import future.keywords.in
import input as tfplan

# Import tag config document from /policy/tag_config
import data.tag_config as tag_config
import data.name_config as name_config
import data.module_config as module_config

# Obtains a list of common mandatory tags from tag-config json file.
get_common_mandatory_tags = x {
	x := tag_config.common.mandatory
}

# Obtains a list of common optional tags from tag-config json file.
get_common_optional_tags = x {
	x := tag_config.common.optional
}

# Obtains a list of relevant resources from each cloud category.
# Concat resources to 1 array
get_resource_type_list = output {
	aws_list := tag_config.infra_list.aws
	gcp_list := tag_config.infra_list.gcp
	azure_list := tag_config.infra_list.azure
	output := array.concat(aws_list, array.concat(gcp_list, azure_list))
}

# Get consolidated mandatory tags by merging common mandatory tags with mandatory resource tags
get_consolidated_mandatory_tags_by_resourceType(r_type) = out {
	# iterate tag config
	some name
	value := tag_config[name]
	
	# merge common mandatory tags with mandatory resource tags
	out := 
		merge_object(tag_config.common.mandatory, filter_mandatory_tags_for_resourceType(r_type, value))
} else = out {
		out := tag_config.common.mandatory
}


get_name_convention_by_resourceType(r_type) = out {
	some name
	value := name_config[name]
	# out := value
	out := filter_name_conventions_for_resourceType(r_type, value)
}

filter_name_conventions_for_resourceType(r_type, resource_config) = out {
	# iterate resources
	some r in resource_config.resources
	r == r_type
	out := resource_config.regex
}

get_acceptable_sources(r_type) = out {
	some source
	value := module_config[source]
	some r in value.resources
	r == r_type

	out := value.accepted_modules
}

using_right_source(acceptable_sources, r_source) = out {
	some r in acceptable_sources
	r == r_source
	out := "true"
}

# Get consolidated optional tags by merging common optional tags with optional resource tags
get_consolidated_optional_tags_by_resourceType(r_type) = out {
	# iterate tag config
	some name
	value := tag_config[name]

	# merge common optional tags with optional resource tags
	out := merge_object(tag_config.common.optional, filter_optional_tags_for_resourceType(r_type, value))
}

# Filter and get the mandatory tags from tag config
filter_mandatory_tags_for_resourceType(rtype, resource_config) = out {
	# iterate resources
	some r in resource_config.resources
	r == rtype
	out := resource_config.mandatory
}

# Filter and get the optional tags from tag config
filter_optional_tags_for_resourceType(rtype, resource_config) = out {
	# iterate resources
	some r in resource_config.resources
	r == rtype
	out := resource_config.optional
}
