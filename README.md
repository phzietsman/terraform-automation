# Terraform Workspace Provisioner
Use this repo to create and manage your TFC or TFE workspaces.

## Terraform Workspace Requirements
In addition to the variables in the `variables.tf` file, you will need the following to add an environment variable `TFE_TOKEN` which will allow the workspace to interact with your TFE / TFC instance.

### Directories
The `workspace_provisioner` contain the terraform code to deploy the provisioner and should be configured at the working directory of the provisioner workspace in TFC / TFE.

The `workspace_definitions` will hold all the yml files that will instruct the provisioner on how the workspace should be setup. This directory should be setup as a trigger_directory in TFC/TCE.

### Workspace definition template
This is what defines what the workspace will look like. It is very much catered to how we use TF + AWS. It expects that there will be default variables and if will add some environment variables to each workspace by default. 

We add the following tf file to all our terraform projects, which helps us ensure uniform naming and tagging across all our resources in AWS. We will over time convert this to either a module or a custom provider.

```hcl
data "aws_caller_identity" "current" {}

// =============================
// Guardrails
// =============================
resource "null_resource" "tf_guard_provider_account_match" {
  count = tonumber(data.aws_caller_identity.current.account_id == var.aws_account_id ? "1" : "fail")
}

// =============================
// Naming
// =============================

locals {
  mandatory_tags = {
    "cat:application" = var.application_name.long
    "cat:client"      = var.client_name.long
    "cat:purpose"     = var.purpose
    "cat:owner"       = var.owner
    "cat:repo"        = var.code_repo
    "cat:nukeable"    = var.nukeable

    "tf:account_id" = data.aws_caller_identity.current.account_id
    "tf:caller_arn" = data.aws_caller_identity.current.arn
    "tf:user_id"    = data.aws_caller_identity.current.user_id

    "app:region"      = var.region
    "app:namespace"   = var.namespace
    "app:environment" = var.environment
  }

  naming_prefix = join("-", [
    var.client_name.short,
    var.application_name.short,
    var.environment,
    var.namespace
  ])
}

// =============================
// Output
// 
// We use various IaC tools and have found SSM Parameters
// a great way to share the output values between systems
// =============================

locals {
  outputs = {
    vpc_id = {
      value  = aws_vpc.example.id
      secure = false
    }
    subnets = {
      value  = [for _, value in aws_subnet.example : value.id]
      secure = false
    }
  }
}

resource "aws_ssm_parameter" "outputs" {

  for_each = local.outputs

  name        = "/${local.naming_prefix}-output/${each.key}"
  description = "Give other systems a handle on this code's outputs"

  type   = each.value["secure"] ? "SecureString" : "String"
  key_id = aws_kms_key.main.arn

  value = jsonencode(each.value["value"])

  tags = merge(local.mandatory_tags, {
    Name = "${local.naming_prefix}-output-${each.key}"
  })
}

// =============================
// Default Variables
// =============================
variable "region" {
  type        = string
  description = "The default region for the application / deployment"
}

variable "environment" {
  type        = string
  description = "Will this deploy a development (dev) or production (prod) environment"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Stage must be either 'dev' or 'prod'."
  }
}

variable "code_repo" {
  type        = string
  description = "Points to the source code used to deploy the resources {{repo}}:{{branch}}"
}

variable "namespace" {
  type        = string
  description = "Used to identify which part of the application these resources belong to (auth, infra, api, web, data)"

  validation {
    condition     = contains(["auth", "infra", "api", "web", "data"], var.namespace)
    error_message = "Namespace needs to be : \"auth\", \"infra\", \"api\" or \"web\"."
  }
}

variable "application_name" {
  type = object({
    short = string
    long  = string
  })
  description = "Used in naming conventions, expecting an object"

  validation {
    condition     = length(var.application_name["short"]) <= 5
    error_message = "The application_name[\"short\"] needs to be less or equal to 5 chars."
  }

}

variable "nukeable" {
  type        = bool
  description = "Can these resources be cleaned up. Will be ignored for prod environments"
}

variable "client_name" {
  type = object({
    short = string
    long  = string
  })
  description = "Used in naming conventions, expecting an object"

  validation {
    condition     = length(var.client_name["short"]) <= 5
    error_message = "The client_name[\"short\"] needs to be less or equal to 5 chars."
  }
}

variable "purpose" {
  type        = string
  description = "Used for cost allocation purposes"

  validation {
    condition     = contains(["rnd", "client", "product"], var.purpose)
    error_message = "Purpose needs to be : \"rnd\", \"client\", \"product\"."
  }
}

variable "owner" {
  type        = string
  description = "Used to find resources owners, expects an email address"

  validation {
    condition     = can(regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", var.owner))
    error_message = "Owner needs to be a valid email address."
  }
}

variable "aws_account_id" {
  type        = string
  description = "Needed for Guards to ensure code is being deployed to the correct account"
}
```

### Ouputs
The provisioner will report on workspaces in your organization that was not creating using this mechanism. 