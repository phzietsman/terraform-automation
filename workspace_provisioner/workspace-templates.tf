locals {
  template_file_names = fileset(local.automation_path, "**/*.yaml")

  template_content = {
    for filename, content in data.template_file.ws_templates :
    filename => yamldecode(content.rendered)
  }
}

data template_file ws_templates {
  // Use for_each to have the resulting output be keyed
  // on the file name and not the order in which it was read
  for_each = local.template_file_names

  template = file("${local.automation_path}/${each.value}")
}

module workspace {
  source = "./modules/workspace"

  for_each = local.template_content

  workspace_content = each.value

  oauth_token_id = var.oauth_token_id
  tfe_organization = var.tfe_organization

  default_terraform_version = var.default_terraform_version

  aws_access_key_id = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}