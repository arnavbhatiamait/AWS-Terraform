locals{
    env = var.enviornment 
    bucket_name = "${var.enviornment}-bucket"
    vpc_name = "${var.enviornment}-vpc"
    ec2_name = "${var.enviornment}-ec2-instance"

}