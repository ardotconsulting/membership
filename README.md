# membership

Manages the [ardotconsulting](https://github.com/ardotconsulting) GitHub organization with [OpenTofu](https://opentofu.org/): who's a member, the org teams, and the repositories along with their per-repo teams.

## Layout

| Path | Manages | Variables |
|------|---------|-----------|
| `members/` | Org membership, org teams (`Admins`, `super-admins`) | `org.tfvars` |
| `repositories/` | Repositories and their per-repo teams | `repositories.tfvars` |

Both modules keep their state in the `ardotconsulting-tofu-state` S3 bucket in us-east-1. Locking uses lock files in the same bucket (`use_lockfile`).

## Prerequisites

- OpenTofu
- AWS credentials that can read and write the state bucket and the lock table
- A GitHub token with org owner permissions, exported as `GITHUB_TOKEN`. The provider reads it from the environment, which keeps it out of saved plans.

## Usage

Apply `members/` before `repositories/`, because `repositories/` reads the `Admins` team.

```sh
export GITHUB_TOKEN=...

tofu -chdir=members init
tofu -chdir=members plan  -var-file=../org.tfvars
tofu -chdir=members apply -var-file=../org.tfvars

tofu -chdir=repositories init
tofu -chdir=repositories plan  -var-file=../repositories.tfvars
tofu -chdir=repositories apply -var-file=../repositories.tfvars
```

Run `tofu fmt -recursive` before you push.

## CI

[docs/setup.md](docs/setup.md) explains how this was set up and why, including the gotchas the first plan caught.

`.github/workflows/zizmor.yml` runs a security audit of the workflows on every PR, on pushes to `main`, and weekly. It's a required check, and findings appear as annotations on the PR.

`.github/workflows/tofu.yml` runs these jobs:

| Trigger | What runs |
|---------|-----------|
| Pull request | `fmt -check` and `validate`, then `plan` for both modules, posted as a PR comment |
| Merge to `main` | `plan`. If anything would change, the saved plans are uploaded, and the `apply` job applies exactly those (`members/` then `repositories/`) after approval in the `production` environment. A merge with no changes finishes without waiting for approval. |
| Mondays at 14:00 UTC, or a manual run | `plan`. If GitHub doesn't match the config, it opens or updates a "OpenTofu drift detected" issue |

The plan, apply and drift jobs log in to GitHub with a GitHub App and to AWS with OIDC. They're skipped until the repo has all three of these:

- variable `TOFU_APP_CLIENT_ID`: the App's client ID
- secret `TOFU_APP_PRIVATE_KEY`: the App's private key
- variable `TOFU_AWS_ROLE_ARN`: the ARN of the IAM role below

The App needs these permissions:
- **Organization:** Members, Administration, and Custom organization roles (all read/write)
- **Repository:** Administration (read/write) and Metadata (read)

### AWS setup (one time)

`aws/trust-policy.json` lets the role be assumed only by same-repo PRs, by `main`, and by the `production` environment. A job that uses an environment presents the environment's name to AWS instead of the branch, which is why it's listed separately. The repo uses GitHub's immutable subject format, so the policy names the org and repo by their numeric IDs (`ardotconsulting@350385434/membership@1441045555`). That way it can't be matched by a renamed or re-created org or repo. To see the current format, run `gh api repos/ardotconsulting/membership/actions/oidc/customization/sub`. `aws/state-policy.json` grants access to the two state files and their lock files, and nothing else.

```sh
account=$(aws sts get-caller-identity --query Account --output text)

# State bucket. Versioning lets you roll back a bad state write.
aws s3api create-bucket --bucket ardotconsulting-tofu-state --region us-east-1
aws s3api put-bucket-versioning --bucket ardotconsulting-tofu-state \
  --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket ardotconsulting-tofu-state \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

aws iam create-role --role-name github-actions-membership-tofu \
  --assume-role-policy-document "$(sed "s/ACCOUNT_ID/$account/" aws/trust-policy.json)"

aws iam put-role-policy --role-name github-actions-membership-tofu \
  --policy-name tofu-state \
  --policy-document file://aws/state-policy.json

gh variable set TOFU_AWS_ROLE_ARN --body "arn:aws:iam::$account:role/github-actions-membership-tofu"
```

If the account already has a GitHub OIDC provider, skip `create-open-id-connect-provider`. If the bucket's default encryption uses a customer-managed KMS key, add `kms:Decrypt` and `kms:GenerateDataKey` on that key to the state policy.

## Common changes

**Add someone to the org:** add their GitHub username to `members` in `org.tfvars`. Put them in `super_admins` instead if they should be an org owner. If a username doesn't exist, it's skipped and listed in the `invalid_users` output.

**Add a repository:** add an entry to `repositories.tfvars`. New repos are created. To bring a repo that already exists on GitHub under management, add a temporary `import` block for `github_repository.this["<name>"]` and `github_repository_collaborators.this["<name>"]`, then remove it once it's applied. Unless `is_ardotconsulting_repo = true`, each repo also gets three teams:

| Team | Permission | Who's on it |
|------|------------|-------------|
| `<repo>` | triage | `members`, `committers`, and `admins` |
| `<repo>-committers` | maintain | `committers` |
| `<repo>-admins` | admin | `admins` |

See `repositories/variables.tofu` for every option and its default.

> [!WARNING]
> Repository collaborators are managed entirely by this config. Anyone added to a repo by hand in GitHub gets removed on the next apply, so give people access through the teams above. When a repository is removed from the config, it's archived, not deleted.
