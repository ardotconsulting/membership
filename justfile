set default-list := true
# Create a private repo in the org, asking for each option, then open a PR that adopts it into OpenTofu
[positional-arguments]
new-repo name:
    #!/usr/bin/env bash
    set -euo pipefail
    name="$1"

    # Check everything before touching GitHub, so a failure can't leave an orphaned repo.
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "invalid repo name: $name" >&2; exit 1; }
    grep -q "^  \"$name\" = {" repositories.tfvars && { echo "$name is already in repositories.tfvars" >&2; exit 1; }
    [[ -z "$(git status --porcelain)" ]] || { echo "working tree isn't clean" >&2; exit 1; }

    # Prompts default to the defaults in repositories/variables.tofu. Only answers
    # that differ from those defaults are written, so the entry stays short.
    entry=""
    add() { entry+="    $1 = $2"$'\n'; }
    hcl_str() { local s="${1//\\/\\\\}"; printf '"%s"' "${s//\"/\\\"}"; }
    hcl_list() { # comma-separated input -> ["a", "b"]
        local out="" item
        IFS=',' read -ra items <<< "$1"
        for item in "${items[@]}"; do
            item="$(echo "$item" | xargs)"
            [[ -n "$item" ]] && out+="${out:+, }$(hcl_str "$item")"
        done
        printf '[%s]' "$out"
    }
    ask() { local reply; read -rp "$1${2:+ [$2]}: " reply; echo "${reply:-$2}"; }
    ask_bool() { # ask_bool <key> <default true|false>
        local hint reply
        [[ "$2" == true ]] && hint="Y/n" || hint="y/N"
        read -rp "$1? [$hint]: " reply
        case "$reply" in
            [yY] | [yY][eE][sS]) reply=true ;;
            [nN] | [nN][oO]) reply=false ;;
            "") reply="$2" ;;
            *) echo "answer y or n" >&2; ask_bool "$1" "$2"; return ;;
        esac
        [[ "$reply" != "$2" ]] && add "$1" "$reply"
        return 0
    }
    ask_str() { # ask_str <key>: blank means unset
        local v; v="$(ask "$1")"
        [[ -n "$v" ]] && add "$1" "$(hcl_str "$v")"
        return 0
    }
    ask_list() { # ask_list <key>: blank means unset
        local v; v="$(ask "$1 (comma-separated)")"
        [[ -n "$v" ]] && add "$1" "$(hcl_list "$v")"
        return 0
    }

    echo "Configuring ardotconsulting/$name (private). Press Enter to keep a default."
    description="$(ask description)"
    add description "$(hcl_str "$description")"
    add visibility '"private"'
    ask_str homepage_url
    ask_list topics

    echo "--- Features"
    ask_bool has_issues true
    ask_bool has_projects true
    ask_bool has_discussions true
    ask_bool has_wiki false
    ask_bool is_template false

    echo "--- Merging"
    ask_bool allow_squash_merge true
    ask_bool allow_merge_commit false
    ask_bool allow_rebase_merge false
    ask_bool allow_auto_merge false
    ask_bool allow_update_branch true
    ask_bool delete_branch_on_merge true
    echo "Valid title/message pairs: PR_TITLE+PR_BODY, PR_TITLE+BLANK, MERGE_MESSAGE+PR_TITLE (squash: COMMIT_OR_PR_TITLE+COMMIT_MESSAGES). Blank keeps GitHub's default."
    ask_str merge_commit_title
    ask_str merge_commit_message
    ask_str squash_merge_commit_title
    ask_str squash_merge_commit_message

    echo "--- Teams"
    ask_bool is_ardotconsulting_repo false
    if ! grep -q "is_ardotconsulting_repo = true" <<< "$entry"; then
        ask_list admins
        ask_list committers
        ask_list members
    fi

    echo "--- Pages"
    pages_on="$(ask "Enable GitHub Pages? (y/N)" n)"
    if [[ "$pages_on" == [yY]* ]]; then
        build_type="$(ask "pages build_type (workflow/legacy)" workflow)"
        cname="$(ask "pages cname (blank for none)")"
        entry+="    pages = {"$'\n'"      build_type = $(hcl_str "$build_type")"$'\n'
        [[ -n "$cname" ]] && entry+="      cname = $(hcl_str "$cname")"$'\n'
        if [[ "$build_type" == legacy ]]; then
            branch="$(ask "pages source branch" main)"
            path="$(ask "pages source path (blank or /docs)")"
            entry+="      source = {"$'\n'"        branch = $(hcl_str "$branch")"$'\n'
            [[ -n "$path" ]] && entry+="        path = $(hcl_str "$path")"$'\n'
            entry+="      }"$'\n'
        fi
        entry+="    }"$'\n'
    fi

    echo "--- Template"
    gh_template=()
    template="$(ask "Create from a template repo? owner/repo (blank for none)")"
    if [[ -n "$template" ]]; then
        [[ "$template" == */* ]] || { echo "template must be owner/repo" >&2; exit 1; }
        all_branches="$(ask "Include all branches from the template? (y/N)" n)"
        [[ "$all_branches" == [yY]* ]] && all_branches=true || all_branches=false
        # The template only takes effect at creation, so gh applies it. It also has to be
        # in the config: the provider forces a replacement if state and config disagree.
        gh_template=(--template "$template")
        [[ "$all_branches" == true ]] && gh_template+=(--include-all-branches)
        entry+="    template = {"$'\n'"      owner = $(hcl_str "${template%%/*}")"$'\n'"      repository = $(hcl_str "${template#*/}")"$'\n'"      include_all_branches = $all_branches"$'\n'"    }"$'\n'
    fi

    printf '\n  "%s" = {\n%s  }\n\n' "$name" "$entry"
    [[ "$(ask "Create the repo and open a PR with this entry? (y/N)" n)" == [yY]* ]] || { echo "aborted, nothing created"; exit 1; }

    git switch main
    git pull --ff-only
    git switch -c "add-repo-$name"

    gh repo create "ardotconsulting/$name" --private --description "$description" "${gh_template[@]}"

    # Drop the map's closing brace, append the entry, close the map again.
    sed -i '' '$d' repositories.tfvars
    printf '  "%s" = {\n%s  }\n}\n' "$name" "$entry" >> repositories.tfvars

    # The repo already exists, so tofu has to import it rather than create it.
    # github_repository_collaborators only exists for repos that get teams.
    import_file="repositories/import-$name.tofu"
    printf '# One-time import of %s, created by `just new-repo`. Remove after it is applied.\nimport {\n  to = github_repository.this["%s"]\n  id = "%s"\n}\n' "$name" "$name" "$name" > "$import_file"
    grep -q "is_ardotconsulting_repo = true" <<< "$entry" ||
        printf '\nimport {\n  to = github_repository_collaborators.this["%s"]\n  id = "%s"\n}\n' "$name" "$name" >> "$import_file"

    tofu fmt -recursive
    git add repositories.tfvars "$import_file"
    git commit -m "➕ add the $name repository"
    git push -u origin "add-repo-$name"
    gh pr create --fill --body "Adds the new private repo \`$name\` to \`repositories.tfvars\` and imports it, since \`just new-repo\` already created it on GitHub.

    Check the plan comment before merging. Once this is applied, delete \`repositories/import-$name.tofu\` in a follow-up PR."
