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
    allow_forking       = true # the agents open PRs from miloardot/infra
    has_discussions     = false
    allow_merge_commit  = true
    allow_rebase_merge  = true
    allow_update_branch = false
    members             = ["miloardot"] # triage: can fork and open PRs, can't push
    topics              = []
    push_allowances     = []
  }
}
