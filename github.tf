# Required Providers
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Provider Configuration
provider "github" {
  # Replace this with your personal access token
#   token = var.github_token
  owner = var.gh_repo_owner
}


resource "github_repository" "exam-repo" {
  count       = var.enable_github ? 1 : 0
  name        = "jupyterhub-exam-${var.exam_name}"
  description = "A Jupyterhub exam repo"

  visibility = "internal"

  template {
    owner                = var.gh_repo_owner
    repository           = var.gh_repo_template
    include_all_branches = false
  }

  lifecycle {
    # keep the repo after other resources are destroyed
    prevent_destroy = true
  }
}

resource "github_actions_secret" "aws_account_id_secret" {
  count            = var.enable_github ? 1 : 0
  repository       = github_repository.exam-repo[0].name
  secret_name      = "AWS_ACCOUNT_ID"
  plaintext_value  = var.aws_account_id

  lifecycle {
    # keep the repo after other resources are destroyed
    prevent_destroy = true
  }
}

resource "github_actions_variable" "exam_name_var" {
  count            = var.enable_github ? 1 : 0
  repository       = github_repository.exam-repo[0].name
  variable_name    = "exam_name"
  value            = var.exam_name

  lifecycle {
    # keep the repo after other resources are destroyed
    prevent_destroy = true
  }
}

# data "github_actions_organization_secrets" "existing_secret" {
# }

# resource "github_actions_organization_secret_repositories" "org_secret_repos" {
#   secret_name = "existing_secret_name"
#   selected_repository_ids = concat(data.github_actions_organization_secrets.existing_secret.secrets[var.project_secret_name].selected_repository_ids, [github_repository.exam-repo.node_id])
#
#   depends_on = [github_repository.exam-repo]
#
#   lifecycle {
#     # keep the repo after other resources are destroyed
#     prevent_destroy = true
#   }
# }
