# Create a private repo in the org, then open a PR that adopts it into OpenTofu
[positional-arguments]
new-repo name description="":
    #!/usr/bin/env bash
    set -euo pipefail
    name="$1"
    description="${2:-}"

    # Check everything before touching GitHub, so a failure can't leave an orphaned repo.
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "invalid repo name: $name" >&2; exit 1; }
    grep -q "^  \"$name\" = {" repositories.tfvars && { echo "$name is already in repositories.tfvars" >&2; exit 1; }
    [[ -z "$(git status --porcelain)" ]] || { echo "working tree isn't clean" >&2; exit 1; }
    git switch main
    git pull --ff-only
    git switch -c "add-repo-$name"

    gh repo create "ardotconsulting/$name" --private --description "$description"

    # Drop the map's closing brace, append the entry, close the map again.
    desc_hcl="${description//\\/\\\\}"
    desc_hcl="${desc_hcl//\"/\\\"}"
    sed -i '' '$d' repositories.tfvars
    printf '  "%s" = {\n    description = "%s"\n    visibility = "private"\n  }\n}\n' "$name" "$desc_hcl" >> repositories.tfvars

    # The repo already exists, so tofu has to import it rather than create it.
    printf '# One-time import of %s, created by `just new-repo`. Remove after it is applied.\nimport {\n  to = github_repository.this["%s"]\n  id = "%s"\n}\n\nimport {\n  to = github_repository_collaborators.this["%s"]\n  id = "%s"\n}\n' \
        "$name" "$name" "$name" "$name" "$name" > "repositories/import-$name.tofu"

    tofu fmt -recursive
    git add repositories.tfvars "repositories/import-$name.tofu"
    git commit -m "➕ add the $name repository"
    git push -u origin "add-repo-$name"
    gh pr create --fill --body "Adds the new private repo \`$name\` to \`repositories.tfvars\` and imports it, since \`just new-repo\` already created it on GitHub.

    Once this is applied, delete \`repositories/import-$name.tofu\` in a follow-up PR."
