# Github Repository Resource
# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository

# Try to import the repository if it already exists
import {
  for_each = var.repositories

  id = each.key
  to = github_repository.this[each.key]
}

resource "github_repository" "this" {
  for_each = var.repositories

  homepage_url                = each.value.homepage_url
  allow_auto_merge            = each.value.allow_auto_merge
  allow_merge_commit          = each.value.allow_merge_commit
  merge_commit_title          = each.value.merge_commit_title
  merge_commit_message        = each.value.merge_commit_message
  allow_rebase_merge          = each.value.allow_rebase_merge
  allow_squash_merge          = each.value.allow_squash_merge
  squash_merge_commit_title   = each.value.squash_merge_commit_title
  squash_merge_commit_message = each.value.squash_merge_commit_message
  allow_update_branch         = each.value.allow_update_branch
  archive_on_destroy          = true
  delete_branch_on_merge      = each.value.delete_branch_on_merge
  description                 = each.value.description
  has_discussions             = each.value.has_discussions
  has_issues                  = each.value.has_issues
  has_projects                = each.value.has_projects
  has_wiki                    = each.value.has_wiki
  is_template                 = each.value.is_template
  name                        = each.key
  topics                      = each.value.topics
  visibility                  = each.value.visibility
  vulnerability_alerts        = true
  dynamic "pages" {
    for_each = each.value.pages != null ? [each.value.pages] : []
    content {
      dynamic "source" {
        for_each = pages.value.source != null ? [pages.value.source] : []
        content {
          branch = source.value.branch
          path   = source.value.path
        }
      }
      build_type = pages.value.build_type
      cname      = pages.value.cname
    }
  }

  dynamic "template" {
    for_each = each.value.template != null ? [each.value.template] : []

    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = template.value.include_all_branches
    }
  }
}