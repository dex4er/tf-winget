# Agent Guide: tf WinGet Package

## Overview

This repository maintains the [WinGet](https://github.com/microsoft/winget-cli)
package `dex4er.tf` of [tf](https://github.com/dex4er/tf), and submits its
manifests to [`microsoft/winget-pkgs`](https://github.com/microsoft/winget-pkgs)
through the fork [`dex4er/winget-pkgs`](https://github.com/dex4er/winget-pkgs).
It follows [`freelensapp/freelens-winget`](https://github.com/freelensapp/freelens-winget).

This repository is not that fork, on purpose: the fork carries the whole
history of winget-pkgs (hundreds of thousands of commits), and every clone of
it, by Renovate or by a workflow, pulls that history in and runs into GitHub
rate limits. The fork is used only for the branches of the pull requests to
upstream, holds only its default branch, and nothing here clones more of it
than its top commit, without blobs, sparse to `manifests/d/dex4er/tf`.

## Repositories and branches

- `dex4er/tf-winget`: this repository, the templates, `make.sh` and CI. Its
  branch `main` is where Renovate bumps the version.
- `dex4er/winget-pkgs`: the fork. Its `master` mirrors
  `microsoft/winget-pkgs:master`, never commit to it; `winget-update.yaml`
  syncs it through the API. Each version goes to the branch
  `dex4er-tf-<version>`.
- `microsoft/winget-pkgs`: upstream, where the pull requests go, from
  `dex4er:dex4er-tf-<version>` to `master`.

## Manifests

The package is `portable`: the plain `tf-windows-amd64.exe` and
`tf-windows-arm64.exe` of a release, which WinGet installs as the command `tf`.
Each version has the three manifests of `template/`: version, installer and
default locale.

The templates are plain YAML with sentinel values, `1.2.3` as the version and
64 `A` as a SHA256, which `make.sh` replaces with `yq`. Change the templates,
never the generated manifests. They keep the style of `microsoft/winget-pkgs`,
CRLF and sequences not indented under their key, which Biome cannot produce:
`biome.jsonc` turns its formatter off for `template/`, `.gitattributes` and
`.editorconfig` keep their CRLF, and `make.sh` formats the generated manifests
with `yamlfmt` and `template/.yamlfmt.yaml`. `yq` turns the empty line after
the `$schema` comment into `#` and quotes `ReleaseDate`; the manifests of
Freelens have the same, and winget-pkgs accepts them.

`make.sh` reads the version of `.versions.yaml`, the date, the URL, the notes
and the assets of the release with `gh`, and the SHA256 of the binaries from
its `checksums.txt`. The WinGet schema allows at most 10000 characters in
`ReleaseNotes`, so longer notes are cut at a whole line and end with a link to
the release. It writes `manifests/d/dex4er/tf/<version>/`, which is
git-ignored here; in `winget-update.yaml` `manifests` is a symlink into the
checkout of the fork.

## Publishing

`winget-update.yaml` runs by hand or on a `/rerun` comment, never on a merge.
It syncs `master` of the fork with `gh repo sync`, as a push from a shallow
clone needs the parent of the new commit on the fork already, clones the fork
shallow and sparse, runs `make.sh`, force-pushes the branch
`dex4er-tf-<version>` and opens the pull request to upstream unless one is
open. The title starts with `New package`, `New version` or `Update`, as
winget-pkgs expects, after whether the package and the version are there
already. `gh auth setup-git` makes `gh` the credential helper, so the token
never lands in `.git/config`.

`GH_TOKEN` of the environment `automated` is used for the sync, the push and
the pull request: a token of the account `dex4er` with write access to the
contents of `dex4er/winget-pkgs` and to pull requests. The workflow token
cannot do it, as it reaches no repository but this one.

`trunk-upgrade.yaml` needs no secret: it pushes `automated/trunk-upgrade` and
opens its pull request with the workflow token, which the setting "Allow
GitHub Actions to create and approve pull requests" of this repository
permits. The token cannot change `.github/workflows`, which `trunk upgrade`
does not touch, and its push starts no workflow, as `[skip ci]` of the commit
would not either.

## Linters and Renovate

Trunk runs the linters of `.trunk/trunk.yaml`: Biome for JSON, Markdown and
YAML (`biome.jsonc`), yamllint for what Biome does not check, shellcheck and
shfmt for `make.sh`, actionlint from the maintained fork `kjanat/actionlint`,
trufflehog and git-diff-check. The definition of Biome runs it in the sandbox
of Trunk with a copy of `biome.jsonc` and matches its report at every line,
where the plugin of Trunk reports only the first issue of a batch.

The version of Biome is pinned with `!` in `.trunk/trunk.yaml`, so that
`trunk upgrade` leaves it and Renovate bumps it. Renovate cannot run
`biome migrate` nor `biome format`, so `biome-migrate.yaml` runs them on its
branch and commits the result as `github-actions[bot]`, which
`gitIgnoredAuthors` of `.renovaterc.json` lists, so that Renovate keeps
updating the branch; the push of the workflow token starts no workflow, so it
starts the checks of the commit with `workflow_dispatch`.

The tools of `make.sh` (`yq`, `yamlfmt`) are in `mise.toml`, with the checksums
and URLs per platform in `mise.lock`. Renovate bumps them, its lock file
maintenance refreshes `mise.lock` and is automerged, and `mise-lock-check.yaml`
fails when a checksum changed while the version of its tool did not. After a
change of `mise.toml`, run `mise lock`, which refreshes every platform;
`mise install` re-locks only its own.

## Validation

Run `trunk check` (`--all` after a broad change) and `mise exec -- bash
make.sh`, then check the manifests of `manifests/d/dex4er/tf/<version>/`. On
Windows, `winget validate --manifest <dir>` validates them, and
`winget install --manifest <dir>` installs them.

## Security

Never read, display or include the contents of `.env`, `.env.*`, `.envrc`,
`.npmrc`, `*.jks`, `*.keystore`, `*.p12`, `*.pfx`, `*.pem` or `*.key`, and
never expose `GH_TOKEN` in logs, comments or generated files. The same list
is git-ignored in `.gitignore` and denied to Claude Code in
`.claude/settings.json`; change the three together.
