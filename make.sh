#!/bin/bash

set -euo pipefail

repo=dex4er/tf
version=$(yq -r .tf .versions.yaml)
dir=manifests/d/dex4er/tf/${version}

gh release view v"${version}" -R "${repo}" --json publishedAt,url,body,assets >release.tmp

releaseDate=$(yq -r '.publishedAt | sub("T.*"; "")' release.tmp)
releaseUrl=$(yq -r .url release.tmp)

asset_url() {
  local url
  url=$(yq -r '.assets[] | select(.name == "'"$1"'") | .url' release.tmp)
  if [[ -z ${url} ]]; then
    echo "No asset $1 in the release v${version} of ${repo}" >&2
    exit 1
  fi
  echo "${url}"
}

installerX64Url=$(asset_url tf-windows-amd64.exe)
installerArm64Url=$(asset_url tf-windows-arm64.exe)

checksumsUrl=$(asset_url checksums.txt)
curl -fsSL "${checksumsUrl}" >checksums.tmp

checksum() {
  local sha256
  sha256=$(perl -lane 'BEGIN { $name = shift } print uc $F[0] if $F[1] eq $name' "$1" checksums.tmp)
  if [[ ! ${sha256} =~ ^[0-9A-F]{64}$ ]]; then
    echo "No checksum of $1 in checksums.txt of the release v${version} of ${repo}" >&2
    exit 1
  fi
  echo "${sha256}"
}

installerX64Sha256=$(checksum tf-windows-amd64.exe)
installerArm64Sha256=$(checksum tf-windows-arm64.exe)

yq -r .body release.tmp | tr -d '\015' | perl -0777 -pe 's/\n*\z//' >release-notes.tmp

# The WinGet schema allows at most 10000 characters in ReleaseNotes. Longer
# notes keep the whole lines that fit, without a heading left empty at the
# end, and end with a link to the release.
RELEASE_URL="${releaseUrl}" MAX_LENGTH=10000 perl -CSD -0777 -i -pe '
  my $more = "\n\n...\n\nFull release notes: $ENV{RELEASE_URL}";
  if (length > $ENV{MAX_LENGTH}) {
    $_ = substr($_, 0, $ENV{MAX_LENGTH} - length $more);
    s/\n[^\n]*\z//;
    1 while s/\n+\z// or s/\n#[^\n]*\z//;
    $_ .= $more;
  }
' release-notes.tmp

mkdir -p "${dir}"

yq '
  .PackageVersion = "'"${version}"'" |
  .ReleaseDate = "'"${releaseDate}"'" |
  (.Installers.[] | select(.Architecture == "x64").InstallerUrl) = "'"${installerX64Url}"'" |
  (.Installers.[] | select(.Architecture == "x64").InstallerSha256) = "'"${installerX64Sha256}"'" |
  (.Installers.[] | select(.Architecture == "arm64").InstallerUrl) = "'"${installerArm64Url}"'" |
  (.Installers.[] | select(.Architecture == "arm64").InstallerSha256) = "'"${installerArm64Sha256}"'"
' template/dex4er.tf.installer.yaml >"${dir}"/dex4er.tf.installer.yaml

yq '
  .PackageVersion = "'"${version}"'" |
  .ReleaseNotes = load_str("release-notes.tmp") |
  .ReleaseNotesUrl = "'"${releaseUrl}"'"
' template/dex4er.tf.locale.en-US.yaml >"${dir}"/dex4er.tf.locale.en-US.yaml

yq '
  .PackageVersion = "'"${version}"'"
' template/dex4er.tf.yaml >"${dir}"/dex4er.tf.yaml

rm -f release.tmp checksums.tmp release-notes.tmp

yamlfmt -conf template/.yamlfmt.yaml "${dir}"/*.yaml
