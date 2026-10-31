# Required Providers
# https://www.terraform.io/docs/language/providers/requirements.html#requiring-providers

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
  }
}

# Github Provider
# https://registry.terraform.io/providers/integrations/github/latest/docs

provider "github" {
  owner = "django-commons"
  token = var.github_token
}