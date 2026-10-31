# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

OpenTofu (not Terraform) config managing the `ardotconsulting` GitHub org via the `integrations/github` provider (pinned `6.9.0`). Files use the `.tofu` extension. There's no application code and no tests.

## Commands

There are two independent root modules, `members/` and `repositories/`. Their `.tfvars` files live at the repo root.

```sh
export TF_VAR_github_token=...            # required by both modules

tofu -chdir=members init
tofu -chdir=members plan  -var-file=../org.tfvars
tofu -chdir=members apply -var-file=../org.tfvars

tofu -chdir=repositories init
tofu -chdir=repositories plan  -var-file=../repositories.tfvars

tofu fmt -recursive                        # format (run before pushing)
tofu -chdir=<module> validate              # after init
```

## Architecture

- **`members/`**: org membership and org-level teams. State goes to S3 (`ardotconsulting-tofu-state`, key `members/tfstate.json`, us-east-1) with DynamoDB locking. `super_admins` get the org `admin` role. `admins` and `members` get `member`; being an "admin" only matters through the `Admins` team, which is granted the Security Manager org role (`role_id = 138`). Usernames are validated through `data.github_users`, and unknown logins are dropped silently and reported in the `invalid_users` output.
- **`repositories/`**: repos plus per-repo teams. State goes to the same S3 bucket under key `repositories/tfstate.json`. It reads the `Admins` team as a data source, so `members/` has to be applied first.
  - Every repo in `var.repositories` gets imported (an `import` block runs on each one) and managed with `archive_on_destroy = true`.
  - For each repo where `is_ardotconsulting_repo = false` there's a team hierarchy: `<repo>` (triage, the parent team holding everyone) → `<repo>-admins` (admin) and `<repo>-committers` (maintain). Team role is `maintainer` when the user belongs to the org `Admins` team (or, on the committers team, to that repo's `admins`).
  - `github_repository_collaborators` is authoritative. It **removes any manually added collaborators** and keeps only the three repo teams (the `Admins` team is ignored).
- Variable names in the `.tfvars` files have to match the `variable` blocks exactly, so check them when adding inputs.
