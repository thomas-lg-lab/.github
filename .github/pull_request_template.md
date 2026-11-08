## Why

<!-- The problem or the goal. Link the issue below rather than repeating it. -->

## What changes

<!-- The approach and anything a reviewer should look at first. -->

## How it was tested

<!-- Commands run, cases covered, what was checked by hand. "Not tested" is a valid answer: say why. -->

## Breaking changes

<!-- Only with `!` in the title: what breaks and how to migrate. Delete this section otherwise. -->

## Checklist

- [ ] Title is a [Conventional Commit](https://www.conventionalcommits.org/): `type(scope): summary`, type among `build chore ci docs feat fix perf refactor revert style test`, `!` for a breaking change (`feat: add X`, `fix(api): correct Y`, `feat!: drop Z`): it becomes the squash commit, the label and the changelog line
- [ ] Tests added or updated for new or changed behaviour
- [ ] Local checks pass (the commands are in the repository's CONTRIBUTING.md or README)
- [ ] Docs updated if behaviour or configuration changed
- [ ] No secret, credential or site-specific value in the diff, the commit messages or this description
- [ ] No hand-made dependency bump (Renovate handles those)

## Related

<!-- `Closes #123` closes the issue on merge. Delete this section if there is none. -->
