# membership

Manages the [ardotconsulting](https://github.com/ardotconsulting) GitHub organization with [OpenTofu](https://opentofu.org/): who's a member, the org teams, and the repositories along with their per-repo teams.

## Layout

| Path | Manages | Variables |
|------|---------|-----------|
| `members/` | Org membership, org teams (`Admins`, `super-admins`) | `org.tfvars` |
| `repositories/` | Repositories and their per-repo teams | `repositories.tfvars` |

Both modules keep their state in the `ardotconsulting-tofu-state` S3 bucket in us-east-1, with locking through DynamoDB.

## Prerequisites

- OpenTofu
- AWS credentials that can read and write the state bucket and the lock table
- A GitHub token with org owner permissions, exported as `TF_VAR_github_token`

## Usage

Apply `members/` before `repositories/`, because `repositories/` reads the `Admins` team.

```sh
export TF_VAR_github_token=...

tofu -chdir=members init
tofu -chdir=members plan  -var-file=../org.tfvars
tofu -chdir=members apply -var-file=../org.tfvars

tofu -chdir=repositories init
tofu -chdir=repositories plan  -var-file=../repositories.tfvars
tofu -chdir=repositories apply -var-file=../repositories.tfvars
```

Run `tofu fmt -recursive` before you push.

## CI

`.github/workflows/tofu.yml` runs these jobs:

| Trigger | What runs |
|---------|-----------|
| Pull request | `fmt -check` and `validate`, then `plan` for both modules, posted as a PR comment |
| Merge to `main` | `apply` for `members/` and then `repositories/`, after approval in the `production` environment |
| Mondays at 14:00 UTC, or a manual run | `plan`. If GitHub doesn't match the config, it opens or updates a "OpenTofu drift detected" issue |

The plan, apply and drift jobs authenticate with a GitHub App. They're skipped until the repo has these two settings:

- variable `TOFU_APP_CLIENT_ID`: the App's client ID
- secret `TOFU_APP_PRIVATE_KEY`: the App's private key

The App needs these permissions:
- **Organization:** Members, Administration, and Custom organization roles (all read/write)
- **Repository:** Administration (read/write) and Metadata (read)

AWS credentials for the state backend are still to be decided (#5).

## Common changes

**Add someone to the org:** add their GitHub username to `members` in `org.tfvars`. Put them in `super_admins` instead if they should be an org owner. If a username doesn't exist, it's skipped and listed in the `invalid_users` output.

**Add a repository:** add an entry to `repositories.tfvars`. Repos that already exist get imported. Unless `is_ardotconsulting_repo = true`, each repo also gets three teams:

| Team | Permission | Who's on it |
|------|------------|-------------|
| `<repo>` | triage | `members`, `committers`, and `admins` |
| `<repo>-committers` | maintain | `committers` |
| `<repo>-admins` | admin | `admins` |

See `repositories/variables.tofu` for every option and its default.

> [!WARNING]
> Repository collaborators are managed entirely by this config. Anyone added to a repo by hand in GitHub gets removed on the next apply, so give people access through the teams above. When a repository is removed from the config, it's archived, not deleted.
