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

variable "bucket_name"{
    default="nfdiu iubsdi fsidbi fwbsdyib uifcbweu8di iwfbiuw dhwiun wwiuecnuicwn ifnwijenfiuw nuwb JDBIBFIUNFIWUNOI FIOWNFOI293U092 u()()() NFNOku wucbwu"
}

variable "multiple_ports"{
    default="80,443,8080"
}
variable "environment"{
    default="dev"
}
variable "instance_size"{
    default={
        dev="t3.micro"
        prod="t3.large"
        stage="t3.medium"
    }
}

variable "instance_type"{
    default="t3.micro"
    validation{
        condition= length(var.instance_type)>=2 && length(var.instance_type)<=20
        error_message="Instance type must be between 2 and 20 characters long."
    }
    validation{
        condition= can(regex("^t3\\.(micro|small|medium|large)$", var.instance_type))
        error_message="Instance type must be one of the following: t3.micro, t3.small, t3.medium, t3.large."
    }
}
variable "backup_name"{
    default="daily_backup"
    validation{
        condition= endswith(var.backup_name, "_backup")
        error_message="Backup name must end with '_backup'."
    }
}

variable credentials{
    default="xyz234"
    sensitive=true
}