output "workspace_id" {
  value = local.create_workspace ? tfe_workspace.this[0].id : "ws-null"
}