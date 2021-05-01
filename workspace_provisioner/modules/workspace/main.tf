resource tfe_workspace this {
  organization = var.tfe_organization

  name              = var.workspace_content.workspace["workspace_name"]
  auto_apply        = var.workspace_content.workspace["auto_apply"]
  working_directory = var.workspace_content.workspace["working_directory"]
  trigger_prefixes  = var.workspace_content.workspace["trigger_prefixes"]
  terraform_version = try(var.workspace_content.workspace["terraform_version"], var.default_terraform_version)

  vcs_repo {
    identifier         = var.workspace_content.workspace["vcs_repo"]["identifier"]
    branch             = var.workspace_content.workspace["vcs_repo"]["branch"]
    oauth_token_id     = var.workspace_content.use_main_vcs_credentials ? var.oauth_token_id : var.workspace_content.workspace["vcs_repo"]["oauth_token_id"]
    ingress_submodules = true
  }
}

// All workspaces will get this variable
resource tfe_variable aws_account_id {

  workspace_id = tfe_workspace.this.id

  key         = "aws_account_id"
  value       = var.workspace_content.aws_account_id
  category    = "terraform"
  description = "The AWS Account in which resources must be provisioned"
  sensitive   = false
}

resource tfe_variable aws_access_key_id {

  workspace_id = tfe_workspace.this.id

  key         = "AWS_ACCESS_KEY_ID"
  value       = var.workspace_content.use_main_aws_credentials ? var.aws_access_key_id : "SET ME"
  category    = "env"
  description = "The access key id for the key from the main account."
  sensitive   = false
}

resource tfe_variable aws_secret_access_key {

  workspace_id = tfe_workspace.this.id

  key         = "AWS_SECRET_ACCESS_KEY"
  value       = var.workspace_content.use_main_aws_credentials ? var.aws_secret_access_key : "SET ME"
  category    = "env"
  description = "The secret access key for the key from the main account."
  sensitive   = true
}

locals {

  tf_variables = {
    for _, value in try(var.workspace_content.workspace["variables"]["terraform"], []) :
    value["key"] => {
      key         = value["key"]
      value       = value["value"]
      description       = value["description"]
      sensitive = try(value["sensitive"], false)
      hcl         = try(value["hcl"], false)
    }
  }

  env_variables = {
    for _, value in try(var.workspace_content.workspace["variables"]["environment"], []) :
    value["key"] => {
      key         = value["key"]
      value       = value["value"]
      description       = value["description"]
      sensitive = try(value["sensitive"], false)
    }
  }


}

/* Dynamic Terraform Variables */
resource tfe_variable terraform {
  for_each = local.tf_variables

  workspace_id = tfe_workspace.this.id
  category    = "terraform"

  key         = each.value["key"]
  value       = each.value["value"]
  description = each.value["description"]
  sensitive   = each.value["sensitive"]
  hcl         = each.value["hcl"]
}

resource tfe_variable environment {
  for_each = local.env_variables

  workspace_id = tfe_workspace.this.id
  category    = "env"

  key         = each.value["key"]
  value       = each.value["value"]
  description = each.value["description"]
  sensitive   = each.value["sensitive"]
}