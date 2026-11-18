# .github/CODEOWNERS for repos with codeowners set: every PR requests these
# users' review, so GitHub emails them. (The org .github repo can't supply this:
# CODEOWNERS isn't a default community health file.)
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file
resource "github_repository_file" "codeowners" {
  for_each = { for k, v in var.repositories : k => v if length(v.codeowners) > 0 }

  repository = github_repository.this[each.key].name
  branch     = "main"
  file       = ".github/CODEOWNERS"
  content = join("\n", concat(
    ["# Managed by ardotconsulting/membership (repositories.tfvars). Every PR",
    "# requests these reviews, so GitHub emails the owners."],
    ["* ${join(" ", [for u in each.value.codeowners : "@${u}"])}"],
    [""],
  ))
  commit_message      = "📬 CODEOWNERS (managed by ardotconsulting/membership)"
  overwrite_on_create = true

  # A protected main only accepts this once the ruleset lets the App bypass it.
  depends_on = [github_repository_ruleset.default_branch]
}
