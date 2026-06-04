output "formatted_project_name" {
    description = "The formatted project name in lowercase"
    value       = local.formatted_project_name
}
output "merged_tags" {
    description = "The merged tags from default and environment"
    value       = local.new_tag
}
output "formatted_bucket_name" {
    description = "The formatted bucket name with spaces replaced by hyphens and truncated to 63 characters"
    value       = local.formatted_bucket_name
}
output "ports_list" {
    description = "The list of ports extracted from the comma-separated string"
    value       = local.ports_list
}
output "sg_rules" {
    description = "The list of security group rules generated from the ports list"
    value       = local.sg_rules
}
output "instance_size" {
    description = "The instance size based on the environment"
    value       = local.instance_size
}
output "credentials" {
    description = "Sensitive credentials output"
    value       = var.credentials
    sensitive   = true
}
output "all_locations" {
    description = "Combined list of user locations and default location"
    value       = local.all_locations
}
output "unique_locations" {
    description = "Unique set of all locations"
    value       = local.unique_locations
}
output "positive_cost" {
    description = "Absolute value of monthly costs"
    value       = local.positive_cost
}