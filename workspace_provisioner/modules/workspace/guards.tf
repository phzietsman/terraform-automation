// Add checks in here to detemine whether the inputs to 
// the modules is sufficient to create the workspace
locals {

  default_vars_present = try(var.workspace_content.workspace["variables"]["default"], []) != []
  other_check          = true

  create_workspace = local.default_vars_present && local.other_check ? 1 : 0

}