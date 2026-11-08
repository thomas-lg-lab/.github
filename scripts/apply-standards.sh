#!/bin/sh
# Applies the organisation's repository standards that no file can carry: merge settings, security features,
# CodeQL default setup, the label set, and the repository's rulesets (.github/rulesets/*.json of the clone it
# runs from). Idempotent: run it after creating a repository, and again after editing a ruleset file.
#
# Usage, from the root of the repository's clone:
#   ../.github/scripts/apply-standards.sh thomas-lg-lab/<name>
# Needs: gh, logged in with admin rights on the repository.
#
# Renovate needs nothing: the organisation's Renovate App covers every repository, and the central runner of
# thomas-lg-lab/renovate-config picks a new one up on its next run.

set -eu

REPO="${1:?usage: apply-standards.sh owner/repo (from the root of its clone)}"
RULESETS_DIR=".github/rulesets"
[ -d "$RULESETS_DIR" ] || { echo "No $RULESETS_DIR here: run this from the root of $REPO's clone." >&2; exit 1; }

echo "Settings: squash only, PR title as commit title, branches deleted on merge, auto-merge allowed"
gh api -X PATCH "repos/$REPO" \
    -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
    -F delete_branch_on_merge=true -F allow_auto_merge=true \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=COMMIT_MESSAGES \
    -F has_wiki=false -F has_projects=false >/dev/null

echo "Security: secret scanning and push protection"
gh api -X PATCH "repos/$REPO" --input - >/dev/null <<'EOF'
{"security_and_analysis": {"secret_scanning": {"status": "enabled"}, "secret_scanning_push_protection": {"status": "enabled"}}}
EOF

echo "Security: private vulnerability reporting (the channel SECURITY.md points to)"
gh api -X PUT "repos/$REPO/private-vulnerability-reporting" >/dev/null

# Alerts only: Dependabot opens no PR, Renovate does. The alerts feed Renovate and the Security tab.
echo "Security: Dependabot alerts"
gh api -X PUT "repos/$REPO/vulnerability-alerts" >/dev/null

# GitHub-managed CodeQL: languages detected by GitHub, analysis on every PR and push to main, no workflow file.
echo "Security: CodeQL default setup"
gh api -X PATCH "repos/$REPO/code-scanning/default-setup" -f state=configured -f query_suite=default >/dev/null

# The labels the autolabeler and Renovate set, and release-drafter reads (.github/release-drafter.yml of the
# organisation's .github repository). Existing labels are updated, others are left alone.
echo "Labels"
label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null; }
label breaking       B60205 "Breaking change (! in the PR title): major version"
label feature        0E8A16 "New capability (feat): minor version"
label enhancement    84B6EB "Improvement of an existing capability (perf): minor version"
label fix            D73A4A "Bug fix (fix, revert)"
label documentation  0075CA "Documentation only (docs)"
label chore          C5DEF5 "Maintenance (build, chore, ci, refactor, style, test)"
label dependencies   0366D6 "Dependency update (Renovate)"
label security       EE0701 "Security fix (Renovate, advisory)"
label github-actions 000000 "GitHub Actions update (Renovate)"

for FILE in "$RULESETS_DIR"/*.json; do
    NAME="$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$FILE" | head -n 1)"
    ID="$(gh api "repos/$REPO/rulesets" --jq ".[] | select(.name == \"$NAME\") | .id")"
    if [ -n "$ID" ]; then
        echo "Ruleset '$NAME': updating ($ID) from $FILE"
        gh api -X PUT "repos/$REPO/rulesets/$ID" --input "$FILE" >/dev/null
    else
        echo "Ruleset '$NAME': creating from $FILE"
        gh api -X POST "repos/$REPO/rulesets" --input "$FILE" >/dev/null
    fi
done

echo "Done."
