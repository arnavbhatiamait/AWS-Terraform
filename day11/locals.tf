locals {
    formatted_project_name = lower(replace(var.project_name, " ", "-"))
}