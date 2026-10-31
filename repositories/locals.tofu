# Local Values
# https://www.terraform.io/language/values/locals

data "github_team" "admins_team" {
  slug = "admins" # GitHub slugifies the "Admins" team name to lowercase
}

locals {
  project_repositories = {
    for repository_key, repository in var.repositories : repository_key => repository
    if !repository.is_ardotconsulting_repo
  }

  admins = data.github_team.admins_team.members
}