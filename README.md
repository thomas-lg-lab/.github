# .github

The organisation's shared standards: default community files, reusable workflows, the Release Drafter
configuration and the script that applies repository settings. A repository carries only what is specific to it.

## Default community files

Used by every repository that has no file of the same kind (a repository's own file replaces the default entirely,
so project-specific details such as local check commands go in its CONTRIBUTING.md instead):

| File | Used for |
| --- | --- |
| `.github/ISSUE_TEMPLATE/` | Issue forms: bug report, feature request, task. Each sets the issue type (Bug, Feature, Task); blank issues are for maintainers only. |
| `.github/pull_request_template.md` | PR description: why, what changes, how it was tested, breaking changes, checklist. |
| `SECURITY.md` | Private vulnerability reporting. |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.0. |
| `profile/README.md` | The organisation's profile page. |

## Reusable workflows

Called from each repository with a few lines, pinned to a commit of a version tag of this repository
(`uses: thomas-lg-lab/.github/.github/workflows/<file>@<sha> # vX.Y.Z`); Renovate moves the pin when a new tag
is published.

| Workflow | Does | Called by |
| --- | --- | --- |
| `pr-conventions.yml` | PR title is a Conventional Commit (`amannn/action-semantic-pull-request`, commitlint types), label from the title (Release Drafter's autolabeler). The `title` job is a required check. | every repository's `pull-request.yml` |
| `release-drafter.yml` | Draft release from the merged PRs; on demand, publish it and dispatch the image build on the new tag. | `release-drafter.yml` of repositories that ship releases |
| `container-image.yml` | Docker image: build and Trivy gate on every PR, publish `edge` and `sha-*` from main, `X.Y.Z` / `latest` from a release tag, build provenance attestation. | the last job of a repository's `ci.yml`, after its tests |
| `registry-cleanup.yml` | Weekly GHCR pruning of `sha-*` tags and untagged layers. | `registry-cleanup.yml` of repositories that publish an image |

`.github/release-drafter.yml` is the Release Drafter configuration of every repository without its own: label
rules from the Conventional Commit type, release note categories and version bump from the labels.

A change here: PR, merge, then publish a release `vX.Y.Z` so callers get it through Renovate.

## Repository settings

`scripts/apply-standards.sh owner/repo`, run from the root of the repository's clone, applies what no file can
carry: merge settings, secret scanning and push protection, private vulnerability reporting, Dependabot alerts,
CodeQL default setup, the label set, and the repository's rulesets (`.github/rulesets/*.json`).

Each repository keeps `LICENSE`, `CODEOWNERS`, `.editorconfig`, `.gitattributes`, `renovate.json` (on top of the
shared preset of `thomas-lg-lab/renovate-config`), its rulesets, a copy of `scorecard.yml` (Scorecard publishing
refuses anything but a plain workflow) and a short `AGENTS.md`.

## Filling issues and PRs (humans and agents)

- The PR title is a Conventional Commit: `type(scope): summary`, type among `build chore ci docs feat fix perf
  refactor revert style test`, `!` after the type for a breaking change. It becomes the squash commit, the label
  and the changelog line.
- Fill every section of the template that applies, delete the others, and say how the change was tested.
  A PR that resolves an issue says `Closes #N`.
- An issue opened through the API or `gh` skips the forms: use the same sections and set the issue type
  (`gh api repos/OWNER/REPO/issues -f title=... -f body=... -f type=Task`, or `Bug`, `Feature`).
- Redact secrets and site-specific values from issues, PRs and logs.
