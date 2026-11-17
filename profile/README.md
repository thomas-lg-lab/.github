Self-hosted tools and the shared tooling behind them.

**Apps**

- **[respawn](https://github.com/thomas-lg-lab/respawn)**: game library with stats, backlog and next-game suggestions (.NET + Angular, PostgreSQL; early days)
- **[digestarr](https://github.com/thomas-lg-lab/digestarr)**: scheduled digest of what was recently added to a media library (Plex, Jellyfin, Emby), posted to Discord
- **[coffee-tracker](https://github.com/thomas-lg-lab/coffee-tracker)**: coffee catalog and tasting journal, label scan with OCR (.NET + Angular, one Docker image)

**Lab**

- **[gitops-lab](https://github.com/thomas-lg-lab/gitops-lab)**: desired state of a k3s lab cluster with Argo CD, Kyverno and CloudNativePG
- **[hello](https://github.com/thomas-lg-lab/hello)**: smallest lab app, the one that proves the path from a commit to the cluster

**Shared tooling**

- **[.github](https://github.com/thomas-lg-lab/.github)**: default community files and the reusable workflows every repository calls (PR conventions, release notes, container image)
- **[repo-template](https://github.com/thomas-lg-lab/repo-template)** and **[renovate-config](https://github.com/thomas-lg-lab/renovate-config)**: the conventions every repository starts from (trunk-based, tagged releases, Renovate, rulesets)
- **[factory](https://github.com/thomas-lg-lab/factory)**: creates a repository from the template with the standards applied
