# Day 13 Notes: Terraform Data Sources

This note explains the data sources used in [day13/main.tf](day13/main.tf) and how they are consumed by the EC2 instance resource.

The lesson demonstrates three data sources:

- `aws_vpc` to find an existing VPC by tag
- `aws_subnet` to find a subnet inside that VPC
- `aws_ami` to find the latest Amazon Linux 2 image

These data sources do not create resources. They read existing AWS infrastructure so Terraform can reference real values during plan and apply.

---

## 1. `data "aws_vpc" "vpc_name"`

```hcl
data "aws_vpc" "vpc_name" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}
```

### What it does

This searches for an existing VPC whose `Name` tag is `default`.

### Why it is used

Terraform often needs a VPC ID before creating or attaching other resources such as subnets, instances, load balancers, or security groups. Instead of hardcoding the VPC ID, you can look it up dynamically.

### Important fields

- `filter` limits the search.
- `name = "tag:Name"` means the AWS tag key `Name`.
- `values = ["default"]` means the VPC must have the tag value `default`.

### Result used later

The VPC ID is read as:

```hcl
data.aws_vpc.vpc_name.id
```

---

## 2. `data "aws_subnet" "shared"`

```hcl
data "aws_subnet" "shared" {
  filter {
    name   = "tag:Name"
    values = ["subneta"]
  }

  vpc_id = data.aws_vpc.vpc_name.id
}
```

### What it does

This looks up a subnet named `subneta`, but only inside the VPC returned by `data.aws_vpc.vpc_name`.

### Why it is used

If your AWS account has many subnets with similar names, adding `vpc_id` makes the lookup safer and prevents Terraform from selecting a subnet from the wrong VPC.

### Important fields

- `filter` searches by tag name.
- `vpc_id = data.aws_vpc.vpc_name.id` scopes the lookup to the matched VPC.

### Result used later

The subnet ID is used here:

```hcl
subnet_id = data.aws_subnet.shared.id
```

---

## 3. `data "aws_ami" "linux2"`

```hcl
data "aws_ami" "linux2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

### What it does

This finds the latest Amazon-owned Amazon Linux 2 AMI matching the name pattern `amzn2-ami-hvm-*-x86_64-gp2`.

### Why it is used

AMI IDs change over time. Hardcoding an AMI ID makes your configuration stale. Using a data source ensures Terraform always fetches the most recent matching image.

### Important fields

- `owners = ["amazon"]` restricts results to AMIs published by Amazon.
- `most_recent = true` chooses the newest matching AMI.
- First `filter` matches the AMI name pattern.
- Second `filter` matches virtualization type.

### Result used later

The AMI ID is used by the EC2 instance:

```hcl
ami = data.aws_ami.linux2.id
```

---

## 4. How the data sources connect to the EC2 instance

```hcl
resource "aws_instance" "example" {
  ami           = data.aws_ami.linux2.id
  count         = var.instance_count
  instance_type = "t3.micro"
  tags          = var.tags
  subnet_id     = data.aws_subnet.shared.id
}
```

### Flow of values

1. Terraform reads the VPC using `data.aws_vpc.vpc_name`.
2. Terraform uses that VPC ID to find the subnet using `data.aws_subnet.shared`.
3. Terraform reads the latest matching AMI using `data.aws_ami.linux2`.
4. Terraform creates EC2 instances using the subnet ID and AMI ID.

### Why this pattern is useful

This is a common Terraform pattern:

- data source to discover existing infrastructure
- resource to create new infrastructure using that discovered data

It keeps the config reusable across environments and avoids hardcoded IDs.

---

## 5. Splat expression in `locals.tf`

Your [day13/locals.tf](day13/locals.tf) shows:

```hcl
locals {
  all_instance_ids = aws_instance.example[*].id
}
```

### What it means

This is a splat expression. Since `aws_instance.example` uses `count`, Terraform creates multiple instances. The splat operator `[*]` collects the `id` from each instance into a list.

### Example result

If 3 instances are created, the output looks like:

```hcl
["i-abc123", "i-def456", "i-ghi789"]
```

### Why it matters

Splat expressions are useful when you need a list of all values from resources created with `count` or `for_each`.

---

## 6. Common patterns and best practices

- Use data sources for existing resources you do not want Terraform to create.
- Prefer tag-based lookup when possible, because IDs can change between environments.
- Narrow data source searches with extra filters such as `vpc_id` or `owners`.
- Use `most_recent = true` for AMIs when you want the latest approved image.
- Use splat expressions when a resource creates multiple instances.

---

## 7. Practical summary

In this lesson, the data sources are helping Terraform answer three questions:

- Which VPC should the resources use?
- Which subnet is inside that VPC?
- Which AMI should the EC2 instances use?

Once Terraform knows those answers, it can create the EC2 instances reliably.

---

## 8. Tiny checklist for this file

- `aws_vpc` finds the VPC by tag.
- `aws_subnet` finds a subnet inside that VPC.
- `aws_ami` finds the latest Amazon Linux 2 image.
- `aws_instance` uses all three values.
- `locals` uses a splat expression to collect instance IDs.

If you want, I can also turn this into a shorter class-note version or add a matching diagram explanation for [day13/DataSource.png](day13/DataSource.png).
