locals {
    formatted_project_name = lower(replace(var.project_name, " ", "-"))
    new_tag=merge(
        var.default_tag,
        var.envionment_tags,
    )
}