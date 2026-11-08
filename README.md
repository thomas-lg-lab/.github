# .github

Default community health files for every repository of the organisation that does not carry its own:

| File | Used for |
| --- | --- |
| `.github/ISSUE_TEMPLATE/` | Issue forms: bug report, feature request, task. Each sets the issue type (Bug, Feature, Task); blank issues are for maintainers only. |
| `.github/pull_request_template.md` | PR description: why, what changes, how it was tested, breaking changes, checklist. |
| `SECURITY.md` | Private vulnerability reporting. |
| `profile/README.md` | The organisation's profile page. |

A repository overrides one of them by adding a file of the same kind; it then ignores the default for that kind
entirely, so keep project-specific details (local check commands, lockfiles) in its CONTRIBUTING.md instead.

## Filling them (humans and agents)

- The PR title is a Conventional Commit with a type from the repository's
  `.github/conventional-commit-types.json`: it becomes the squash commit, the label and the changelog line.
- Fill every section that applies, delete the ones that do not, and say how the change was tested.
  A PR that resolves an issue says `Closes #N`.
- An issue opened through the API or `gh` skips the forms: use the same sections and set the issue
  type (`gh api repos/OWNER/REPO/issues -f title=... -f body=... -f type=Task`, or `Bug`, `Feature`).
- Redact secrets and site-specific values from issues, PRs and logs.
