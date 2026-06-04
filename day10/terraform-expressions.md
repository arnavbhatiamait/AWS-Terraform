## Terraform Expressions — Notes

This file summarizes the Terraform expression types shown in the course image: Conditional Expressions, Dynamic Blocks, and Splat Expressions. Each section includes syntax and short HCL examples you can paste into your configs.

---

### Conditional Expressions

Syntax:

condition ? true_value : false_value

Use to choose values based on variables or conditions (e.g. environment-based sizing or toggles).

Example:

```hcl
variable "env" { default = "dev" }

locals {
  instance_type = var.env == "prod" ? "t3.large" : "t3.micro"
  enable_monitor = var.env == "prod" ? true : false
}

resource "aws_instance" "app" {
  ami           = "ami-0123456789abcdef0"
  instance_type = local.instance_type
  tags = {
    Environment = var.env
  }
}
```

Common uses:

- Choose AMIs by region
- Enable/disable features (monitoring, backups)
- Select sizes/counts based on environment

---

### Dynamic Blocks

Dynamic blocks generate nested blocks (like `ingress`, `egress`, or `tags`) from a collection.

Syntax:

dynamic "block_name" {
  for_each = var.collection
  content {
    # block body using block_name.value (or .key/.value for maps)
  }
}

Example (security group ingress rules):

```hcl
variable "ingresses" {
  description = "List of maps with from_port/to_port/protocol/cidr"
  type = list(object({ from_port = number, to_port = number, protocol = string, cidr = string }))
}

resource "aws_security_group" "sg" {
  name = "example-sg"

  dynamic "ingress" {
    for_each = var.ingresses
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
    }
  }
}
```

Notes:

- `ingress.value` accesses each element; if iterating a map you can use `ingress.key` and `ingress.value`.
- Useful when the number or content of nested blocks is dynamic.

---

### Splat Expressions

Splat expressions provide a compact way to access an attribute across all instances in a list or resource with `[*]`.

Syntax examples:

- `resource_list[*].attribute` — returns a list of attributes
- `resource_list[0].attribute` — index into instances

Example:

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
}

output "web_private_ips" {
  value = aws_instance.web[*].private_ip
}

output "first_web_id" {
  value = aws_instance.web[0].id
}
```

Notes:

- Use splat when you want to aggregate attributes from multiple instances into a list.
- Combined with `flatten()` or `compact()` for nested lists and filtering.

---

### Quick reference

- Conditional: `condition ? true_value : false_value`
- Dynamic block: `dynamic "name" { for_each = var.coll content { ... } }`
- Splat: `resource[*].attr` or `resource[index].attr`

If you'd like, I can add more examples (maps, for-expressions, functions) or integrate these into one real module example.
