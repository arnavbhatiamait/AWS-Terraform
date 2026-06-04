locals{
    all_instance_ids=aws_instance.example[*].id
}
# ! * is splat operator to get all the ids of the instances created by the aws_instance resource with count
