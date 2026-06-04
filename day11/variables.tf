variable "project_name"{
    description = "The name of the project ALPHA "
    type        = string
    default     = "Proj ALPHA"
}
variable "default_tag"{
    default={
        compant = "My Company"
        managed_by   = "Arnav Bhatia"
    }
}
variable "envionment_tags"{
    default={
        environment = "Development"
        cost_center = "CC-123"
    }
}