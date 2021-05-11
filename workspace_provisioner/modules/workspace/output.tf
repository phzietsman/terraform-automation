output "workspace_id" {
  value = local.create_workspace == 1 ? tfe_workspace.this[0].id : "ws-null"
}