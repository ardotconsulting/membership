# Default branch protection for repos with protect_default_branch = true.
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset
resource "github_repository_ruleset" "default_branch" {
  for_each = { for k, v in var.repositories : k => v if v.protect_default_branch }

  name        = "protect default branch"
  repository  = github_repository.this[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Org admins (Ryan) can merge their own PRs without a second reviewer, but
  # still only through a PR.
  bypass_actors {
    actor_id    = 0 # GitHub ignores the ID for OrganizationAdmin and stores 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }

  # This repo's GitHub App (ardotconsulting-tofu), so it can write managed files
  # such as .github/CODEOWNERS to a protected main.
  bypass_actors {
    actor_id    = 5558573
    actor_type  = "Integration"
    bypass_mode = "always"
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 1
    }
  }
}
