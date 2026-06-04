locals {
    formatted_project_name = lower(replace(var.project_name, " ", "-"))
    new_tag=merge(
        var.default_tag,
        var.envionment_tags,
    )
    formatted_bucket_name=replace(replace(lower(substr(var.bucket_name,0,63)), " ", "-"), "()", "-")
    ports_list=split(",", var.multiple_ports)
    sg_rules=[
        for port in local.ports_list : {
            name = "Allow port ${port}"
            port = port
            description = "Allow traffic on port ${port}"
        }
    ]
    instance_size=lookup(var.instance_size, var.environment, "t3.micro")
}