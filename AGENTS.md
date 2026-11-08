# Working on this repository (humans and agents)

- This repository is the organisation's shared standards; its README says what each file is for and how to fill
  issues and PRs. A change here reaches every repository: keep it backwards compatible or update the callers.
- Trunk-based: short branch, one squash PR into `main`, signed commits. PR titles are Conventional Commits.
- A change to a reusable workflow ships as a release `vX.Y.Z` (semver: a breaking input change is a major), then
  Renovate moves the callers.
- Actions are pinned to commit SHAs (Renovate keeps them current). Secrets never go in the repository.
- Technical files are written in English.
