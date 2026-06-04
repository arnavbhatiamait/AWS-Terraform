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

    all_locations=concat(var.user_locations, var.default_location)
    unique_locations=toset(local.all_locations)
    positive_cost=[for cost in var.monthly_costs : abs(cost)]
 max_cost     = max(local.positive_cost...)
  min_cost     = min(local.positive_cost...)
  total_cost   = sum(local.positive_cost)
  average_cost = local.total_cost / length(local.positive_cost)
  currrent_time = timestamp()
  format1=formatdate("YYYY-MM-DD HH:mm:ss", timestamp())
  format2=formatdate("DD/MM/YYYY", timestamp())

    config_file_exists=fileexists("./config.json")
    config_data=fileexists("./config.json") ? jsondecode(file("./config.json")) : {
        bucket_name = "default-bucket-name"
        default_tag = {
            Owner = "Default Owner"
            Project = "Default Project"
        }
        envionment_tags = {
            Environment = "Default Environment"
        }
    }

}