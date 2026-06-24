# Terraform Modules: Comprehensive Study Notes

This guide covers everything you need to know about **Terraform Modules**, including their definition, why we use them, how to create and structure custom modules, how to call them, how to leverage public/inbuilt modules from the Terraform Registry, and how these concepts apply to this repository's infrastructure configuration.

---

## Table of Contents
1. [Introduction to Terraform Modules](#1-introduction-to-terraform-modules)
2. [Why Use Modules?](#2-why-use-modules)
3. [Creating a Custom Module](#3-creating-a-custom-module)
4. [Using (Calling) a Module](#4-using-calling-a-module)
5. [Using Public / Inbuilt Registry Modules](#5-using-public--inbuilt-registry-modules)
6. [Mapping Concepts to This Repository](#6-mapping-concepts-to-this-repository)
7. [Best Practices for Designing Modules](#7-best-practices-for-designing-modules)

---

## 1. Introduction to Terraform Modules

A **Module** is a container for multiple resources that are used together. You can think of a module as the Terraform equivalent of a **function** or a **package** in programming languages. 

Every Terraform configuration has at least one module, known as the **Root Module**. 
* **Root Module**: The directory containing the `.tf` files you run `terraform apply` on.
* **Child Module**: A separate module called by another configuration (e.g., calling `./modules/vpc` from the root [main.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/main.tf)).

```
                  ┌──────────────────────┐
                  │     Root Module      │
                  │     (main.tf)        │
                  └──────────┬───────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
┌──────────────────────┐            ┌──────────────────────┐
│  Child Module (VPC)  │            │  Child Module (IAM)  │
│  (./modules/vpc)     │            │  (./modules/iam)     │
└──────────────────────┘            └──────────────────────┘
```

---

## 2. Why Use Modules?

Without modules, all resources are defined in a single, large block of configuration files. This leads to code duplication, increased blast radius, and difficult maintenance. Modules solve these issues by providing:

1. **Organize Configuration**: Grouping related resources (e.g., VPC, Subnets, NAT Gateways) makes the codebase easier to read and understand.
2. **Encapsulate Complexity**: Abstracting low-level details. The calling configuration only needs to pass a few high-level parameters instead of defining dozens of resource blocks.
3. **Reusability**: Write a standard infrastructure block (e.g., an EKS cluster or S3 bucket) once, and reuse it across multiple environments (Dev, Staging, Production).
4. **Consistency & Standards**: Ensure security guidelines, tagging policies, and design patterns are enforced uniformly.
5. **Reduced Blast Radius**: Isolating configurations helps minimize the impact of changes.

---

## 3. Creating a Custom Module

Creating a module is as simple as creating a new folder and writing `.tf` files in it. Any directory containing Terraform files can be loaded as a module.

### Standard Module File Structure
A standard Terraform module should follow this structure:
```text
modules/my-module/
├── main.tf      # Primary resource definitions
├── variables.tf # Input variables (like function arguments)
├── outputs.tf   # Output values (like function return values)
├── README.md    # Documentation for users of the module
└── locals.tf    # Local variables for internal computations (optional)
```

### Flow of Data in a Module
```
[Parent configuration] ──(Input Variables)──> [Child Module] ──(Outputs)──> [Parent/Other Modules]
```

### Example: Creating a Simple Custom VPC Module
Let's review the structure of a custom VPC module, matching the one in [modules/vpc/](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/modules/vpc).

#### 1. Input Variables (`variables.tf`)
Variables act as inputs to customize the module's behavior.
```hcl
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets CIDRs"
}
```

#### 2. Resources (`main.tf`)
The actual resources defined using the input variables.
```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "custom-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  
  tags = {
    Name = "public-subnet-${count.index}"
  }
}
```

#### 3. Outputs (`outputs.tf`)
Outputs expose information about the resources created inside the module, allowing other resources or modules to use them.
```hcl
output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "A list of public subnet IDs"
}
```

---

## 4. Using (Calling) a Module

To use a child module, declare a `module` block in your parent configuration (typically the root `main.tf`).

### Module Declaration Syntax
```hcl
module "vpc" {
  source = "./modules/vpc" # Required: Path or URL to the module

  # Inputs defined in the module's variables.tf
  vpc_cidr       = "10.1.0.0/16"
  public_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
}
```

### Accessing Module Outputs
To use the return values (outputs) from a module elsewhere in your configuration, use the syntax: `module.<MODULE_NAME>.<OUTPUT_NAME>`.

For example, to launch an EC2 instance in the VPC created by the module above:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  
  # Accessing the module output:
  subnet_id     = module.vpc.public_subnet_ids[0]
}
```

### Module Meta-Arguments
Like resources, modules support several meta-arguments:

* **`count`**: Conditionally create or scale a module.
  ```hcl
  module "secrets" {
    source = "./modules/secrets-manager"
    count  = var.enable_secrets ? 1 : 0
  }
  ```
* **`for_each`**: Create multiple instances of a module based on a map or set.
  ```hcl
  module "app_clusters" {
    source   = "./modules/eks"
    for_each = toset(["dev", "prod"])
    
    cluster_name = "eks-${each.key}"
  }
  ```
* **`depends_on`**: Explicitly specify dependencies when Terraform cannot infer them automatically.
  ```hcl
  module "eks" {
    source     = "./modules/eks"
    depends_on = [module.iam] # Ensures IAM policies/roles are created first
  }
  ```
* **`providers`**: Pass non-default provider configurations to a module.
  ```hcl
  module "vpc_secondary" {
    source = "./modules/vpc"
    providers = {
      aws = aws.us_west_2 # Pass an aliased provider
    }
  }
  ```

---

## 5. Using Public / Inbuilt Registry Modules

Rather than writing custom modules for common infrastructure patterns, you can download public modules from the [Terraform Registry](https://registry.terraform.io/).

### Example: Calling a Registry VPC Module
Here is how you would call the official AWS VPC module hosted on the Terraform Registry:

```hcl
module "public_vpc" {
  # Format: <NAMESPACE>/<NAME>/<PROVIDER>
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1" # HIGHLY RECOMMENDED: Lock the version

  name = "my-registry-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Key Differences: Custom vs. Public Registry Modules

| Aspect | Custom Modules (Local) | Public Registry Modules |
| :--- | :--- | :--- |
| **Control** | Complete ownership over every resource. | Relies on community maintenance. |
| **Source Path** | Starts with `./` or `../` pointing to local directory. | Named string like `terraform-aws-modules/...` or Git URLs. |
| **Updates** | Modified manually in place. | Handled via version constraints and `terraform init -upgrade`. |
| **Complexity** | Simple, tailored directly to your organization. | Often highly complex to support generic use cases. |
| **Auditability** | Easy to inspect inside your repo. | Requires auditing external code before using. |

### Module Sources in Terraform
Terraform supports various sources for `source`:
* **Local paths**: `./modules/vpc`
* **Terraform Registry**: `terraform-aws-modules/vpc/aws`
* **GitHub (HTTPS)**: `github.com/terraform-aws-modules/terraform-aws-vpc`
* **GitHub (SSH)**: `git@github.com:terraform-aws-modules/terraform-aws-vpc.git`
* **Generic Git repositories with branches/tags**: `git::https://example.com/vpc.git?ref=v1.2.0`
* **S3 Buckets**: `s3::https://s3.amazonaws.com/my-terraform-modules/vpc.zip`

---

## 6. Mapping Concepts to This Repository

This repository represents a real-time EKS Cluster deployment utilizing custom modules. Let's analyze how modules are configured and connected here:

### 1. Repository Structure
The repository is split into a **Root Module** and **four Child Modules**:
* **Root Module Files**:
  * [main.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/main.tf): Declares and configures the child modules.
  * [variables.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/variables.tf): Sets global variables passed down to modules.
  * [outputs.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/outputs.tf): Exposes combined outputs from the child modules.
* **Child Modules** ([modules/](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/modules)):
  * `vpc`: Networking configurations (VPC, Route Tables, IGW, NAT Gateways).
  * `iam`: IAM Roles and OIDC provider configs required by EKS.
  * `eks`: The EKS Cluster control plane and Node Groups.
  * `secrets-manager`: Secrets encryption keys and AWS secrets parameters.

### 2. The Dependency Chain & Output Passing
In [main.tf](file:///C:/Users/ArnavBhatia/Desktop/arnav/udemy/Terraform/yt-piyush/day20/main.tf), we pass outputs from one module to another. This creates implicit dependencies that Terraform uses to plan the creation order.

* **VPC Outputs to EKS**: EKS requires a VPC and subnet IDs to deploy the control plane and worker nodes.
  ```hcl
  # In main.tf
  module "eks" {
    source     = "./modules/eks"
    vpc_id     = module.vpc.vpc_id           # Output from module.vpc
    subnet_ids = module.vpc.private_subnets  # Output from module.vpc
    # ...
  }
  ```
* **IAM Outputs to EKS**: EKS requires IAM role ARNs to assign policies to the Control Plane and worker nodes.
  ```hcl
  # In main.tf
  module "eks" {
    source           = "./modules/eks"
    cluster_role_arn = module.iam.cluster_role_arn       # Output from module.iam
    node_role_arn    = module.iam.node_group_role_arn    # Output from module.iam
    # ...
  }
  ```
* **Explicit Dependency**: EKS relies on IAM roles being fully created and active. We use `depends_on` to ensure the IAM module finishes applying first:
  ```hcl
  # In main.tf
  module "eks" {
    source     = "./modules/eks"
    # ...
    depends_on = [module.iam]
  }
  ```

---

## 7. Best Practices for Designing Modules

1. **Rule of Three**: Don't build a custom module unless you intend to reuse the configuration in at least three places, OR if the configuration is exceptionally complex and benefits from encapsulation.
2. **Keep Modules Focused**: A module should build one logical piece of infrastructure (e.g., a database tier, a Kubernetes cluster, a static website). Avoid building a single "monolithic module" that builds your entire cloud account.
3. **Use Version Constraints**: When using public or remote modules, always lock the module version using `version = "~> X.Y.Z"` to prevent accidental upgrades that introduce breaking changes.
4. **Publish Outputs Generously**: Export any resource attribute that a user of your module might need. It is easier to add outputs than to refactor dependent configurations later.
5. **Document Inputs & Outputs**: Use the `description` attribute on all input variables and outputs. This serves as self-documenting code.
6. **Avoid Hardcoding**: Make values like IP ranges, instance sizes, regions, and environment tags configurable via variables rather than hardcoding them in the module's `main.tf`.

---

## Cheat Sheet: Commands for Modules

| Command | Purpose |
| :--- | :--- |
| `terraform init` | Downloads remote modules and registers local module structures. Run this every time you add/modify a `module` block. |
| `terraform init -upgrade` | Checks for and downloads newer versions of remote/registry modules matching your version constraints. |
| `terraform get` | Downloads/updates module code without performing a full initialization. |
| `terraform state list` | Shows resources in state. Resources inside modules will be prefixed with `module.<MODULE_NAME>.<RESOURCE_TYPE>.<NAME>`. |
