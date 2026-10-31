# Required Providers
# https://www.terraform.io/docs/language/providers/requirements.html#requiring-providers

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

# Github Provider
# https://registry.terraform.io/providers/integrations/github/latest/docs

provider "github" {
  owner = "ardotconsulting"
  # token comes from the GITHUB_TOKEN environment variable, which keeps it out of saved plans
}