data "tfe_workspace_ids" "all" {
  names        = ["*"]
  organization = var.tfe_organization
}

locals {

  managed_workspace_ids = [for _, workspace in module.workspace : workspace.outputs["workspace_id"] if workspace.outputs["workspace_id"] != "ws-null"]
  all_workspace_ids     = [for _, workspace_id in data.tfe_workspace_ids.all.ids : workspace_id]

  unmanaged_workspace_ids   = setsubtract(local.all_workspace_ids, local.managed_workspace_ids)
  unmanaged_workspace_names = [for workspace_name, workspace_id in data.tfe_workspace_ids.all.ids : { "name" = workspace_name, "id" = workspace_id } if contains(local.unmanaged_workspace_ids, workspace_id) && !contains(var.unmanaged_workspaces_exceptions, workspace_name)]
}


output "unmanaged_workspaces" {
  value = local.unmanaged_workspace_names
}