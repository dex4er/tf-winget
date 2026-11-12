# tf-winget

[![release](https://img.shields.io/github/v/release/dex4er/tf?display_name=tag&sort=semver)](https://github.com/dex4er/tf/releases/latest)
[![WinGet Package Version](https://img.shields.io/winget/v/dex4er.tf)](https://winstall.app/apps/dex4er.tf)

Automated updates of the WinGet package of [tf](https://github.com/dex4er/tf).

The manifests are generated here and submitted to
[microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs) through the
fork [dex4er/winget-pkgs](https://github.com/dex4er/winget-pkgs).

Install:

```powershell
winget install dex4er.tf
```

## Publishing a new version

Renovate opens a pull request that bumps the version in `.versions.yaml`.
After its merge, run the workflow
[Automated WinGet update](https://github.com/dex4er/tf-winget/actions/workflows/winget-update.yaml)
by hand, or comment `/rerun` on any issue or pull request of this repository.
It opens the pull request to microsoft/winget-pkgs.

Generate the manifests locally into `manifests/` (needs `gh` with a token):

```sh
mise exec -- bash make.sh
```
