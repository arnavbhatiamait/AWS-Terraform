resource "aws_s3_bucket" "bucket1"{
    count=2
    # ! it will count from 0 to 1 and create 2 buckets with the names provided in the variable bucket_names
    bucket = var.bucket_names[count.index]
    tags=var.tags
}

resource "aws_s3_bucket" "bucket2"{
   for_each=var.bucket_names_set 
    bucket = each.value
    tags=var.tags
}