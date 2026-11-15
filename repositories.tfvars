repositories = {
  ".github" = {
    description     = "The repository for managing Ardot Consulting organizational profile."
    has_discussions = true
    has_issues      = true
    topics          = []
    push_allowances = []
  }
  "marketing-plan" = {
    description     = "The marketing plan repository for Ardot Consulting."
    visibility      = "private"
    has_discussions = true
    has_issues      = true
    topics          = []
    push_allowances = []
  }
  "ardotconsulting-site" = {
    description     = "The Website for Ardot Consulting."
    homepage_url    = "https://www.ardotconsulting.com/"
    committers      = ["miloardot"] # the agents publish blog posts
    has_discussions = true
    has_issues      = true
    topics          = []
    push_allowances = []
    pages = {
      build_type = "workflow"
      cname      = "www.ardotconsulting.com"
    }
  }
  "infra" = {
    description         = "OpenTofu for the ardotconsulting lab."
    visibility          = "private"
    allow_forking       = false # agents use the pocs repo, not a fork of infra
    has_discussions     = false
    allow_merge_commit  = true
    allow_rebase_merge  = true
    allow_update_branch = false
    members             = ["miloardot"] # triage: can fork and open PRs, can't push
    topics              = []
    push_allowances     = []
  }
  "pocs" = {
    description            = "Proofs of concept from the ardotconsulting blog, deployed on the lab Coolify with OpenTofu."
    auto_init              = true
    protect_default_branch = true
    has_discussions        = false
    committers             = ["miloardot"] # the agents propose POCs here; Ryan approves and applies
    environments = {
      plan       = {}                             # CI plans with the stack's secrets
      production = { reviewers = ["ryancheley"] } # CI applies after Ryan approves
    }
    topics          = []
    push_allowances = []
  }
}
