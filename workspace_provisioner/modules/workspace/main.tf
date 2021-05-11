resource "tfe_workspace" "this" {

  count = local.create_workspace

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

// All workspaces will get these variables
resource "tfe_variable" "aws_account_id" {
  count        = local.create_workspace
  workspace_id = tfe_workspace.this[0].id

  key         = "aws_account_id"
  value       = var.workspace_content.aws_account_id
  category    = "terraform"
  description = "The AWS Account in which resources must be provisioned"
  sensitive   = false
}

resource "tfe_variable" "aws_access_key_id" {
  count        = local.create_workspace
  workspace_id = tfe_workspace.this[0].id

  key         = "AWS_ACCESS_KEY_ID"
  value       = var.workspace_content.use_main_aws_credentials ? var.aws_access_key_id : "SET ME"
  category    = "env"
  description = "The access key id for the key from the main account."
  sensitive   = false
}

resource "tfe_variable" "aws_secret_access_key" {
  count        = local.create_workspace
  workspace_id = tfe_workspace.this[0].id

  key         = "AWS_SECRET_ACCESS_KEY"
  value       = var.workspace_content.use_main_aws_credentials ? var.aws_secret_access_key : "SET ME"
  category    = "env"
  description = "The secret access key for the key from the main account."
  sensitive   = true
}

locals {

  default_variables_pre_check = {
    for _, value in try(var.workspace_content.workspace["variables"]["default"], []) :
    value["key"] => {
      key         = value["key"]
      value       = value["value"]
      description = value["description"]
      sensitive   = try(value["sensitive"], false)
      hcl         = try(value["hcl"], false)
    }
  }

  tf_variables_pre_check = {
    for _, value in try(var.workspace_content.workspace["variables"]["terraform"], []) :
    value["key"] => {
      key         = value["key"]
      value       = value["value"]
      description = value["description"]
      sensitive   = try(value["sensitive"], false)
      hcl         = try(value["hcl"], false)
    }
  }

  env_variables_pre_check = {
    for _, value in try(var.workspace_content.workspace["variables"]["environment"], []) :
    value["key"] => {
      key         = value["key"]
      value       = value["value"]
      description = value["description"]
      sensitive   = try(value["sensitive"], false)
    }
  }

  default_variables = local.create_workspace == 1 ? local.default_variables_pre_check : {}
  tf_variables      = local.create_workspace == 1 ? local.tf_variables_pre_check : {}
  env_variables     = local.create_workspace == 1 ? local.env_variables_pre_check : {}

}


resource "tfe_variable" "default" {
  for_each = local.default_variables

  workspace_id = tfe_workspace.this[0].id
  category     = "terraform"

  key         = each.value["key"]
  value       = each.value["value"]
  description = each.value["description"]
  sensitive   = each.value["sensitive"]
  hcl         = each.value["hcl"]
}

/* Dynamic Terraform Variables */
resource "tfe_variable" "terraform" {
  for_each = local.tf_variables

  workspace_id = tfe_workspace.this[0].id
  category     = "terraform"

  key         = each.value["key"]
  value       = each.value["value"]
  description = each.value["description"]
  sensitive   = each.value["sensitive"]
  hcl         = each.value["hcl"]
}

resource "tfe_variable" "environment" {
  for_each = local.env_variables

  workspace_id = tfe_workspace.this[0].id
  category     = "env"

  key         = each.value["key"]
  value       = each.value["value"]
  description = each.value["description"]
  sensitive   = each.value["sensitive"]
}