variable tfe_organization {
  type        = string
  description = "The TFC organization to create the workspaces in."
}

variable "default_terraform_version" {
  type = string
  description = "The default terraform version for workspaces"
  default = "0.14.0"
}

variable oauth_token_id {
  type        = string
  description = "Bitbucket OAuth token Id used to by TFC. Associate a workspace with this VCS"
}

variable aws_access_key_id {
  type        = string
  sensitive = false
  description = "The default credentials used in the created workspaces."
}

variable aws_secret_access_key {
  type        = string
  sensitive = true
  description = "The default credentials used in the created workspaces."
}
