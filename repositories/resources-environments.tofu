# Deployment environments. Each is limited to main, so a workflow on any other
# branch can't use its secrets.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment

locals {
  repo_environments = {
    for item in flatten([
      for repo, r in var.repositories : [
        for env, e in r.environments : { repository = repo, environment = env, reviewers = e.reviewers }
      ]
    ]) : "${item.repository}/${item.environment}" => item
  }
}

data "github_user" "environment_reviewers" {
  for_each = toset(flatten([for e in local.repo_environments : tolist(e.reviewers)]))

  username = each.value
}

resource "github_repository_environment" "this" {
  for_each = local.repo_environments

  repository  = github_repository.this[each.value.repository].name
  environment = each.value.environment

  dynamic "reviewers" {
    for_each = length(each.value.reviewers) > 0 ? [each.value.reviewers] : []
    content {
      users = [for u in reviewers.value : tonumber(data.github_user.environment_reviewers[u].id)]
    }
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "main" {
  for_each = local.repo_environments

  repository     = github_repository.this[each.value.repository].name
  environment    = github_repository_environment.this[each.key].environment
  branch_pattern = "main"
}
