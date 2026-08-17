#!/bin/bash
set -Eeuo pipefail

readonly bootstrap_dir="/var/tmp/pios-bootstrap"
readonly repo_dir="${HOME}/pios"
readonly installer_url="https://install.determinate.systems/nix/tag/v3.22.0/nix-installer-aarch64-darwin"
readonly installer_sha256="26dabfc07aaa7c5ece7a872b37e73099a6dc3b091b6b648fe812b04e3a8f1e84"

load_nix() {
  [[ -x /nix/var/nix/profiles/default/bin/nix ]]
  PATH="/nix/var/nix/profiles/default/bin:${PATH}"
  export PATH
}

verify_host() {
  local macos_version
  local sdk_version
  local swift_version
  local xcode_version

  [[ "$(/usr/bin/uname -s)" == "Darwin" ]]
  [[ "$(/usr/bin/uname -m)" == "arm64" ]]

  macos_version="$(/usr/bin/sw_vers -productVersion)"
  [[ ${macos_version} == 26.* ]]

  /usr/bin/xcodebuild -checkFirstLaunchStatus
  xcode_version="$(/usr/bin/xcodebuild -version)"
  [[ ${xcode_version%%$'\n'*} == "Xcode 26"* ]]
  if /usr/bin/grep -qi beta <<<"${xcode_version}"; then
    printf 'error: beta Xcode is not accepted\n' >&2
    exit 1
  fi

  sdk_version="$(/usr/bin/xcrun --sdk iphoneos --show-sdk-version)"
  [[ -n ${sdk_version} ]]
  swift_version="$(/usr/bin/xcrun swift --version)"

  printf 'FACT user=%s uid=%s\n' "$(/usr/bin/id -un)" "$(/usr/bin/id -u)"
  printf 'FACT uname=%s %s\n' "$(/usr/bin/uname -s)" "$(/usr/bin/uname -m)"
  printf 'FACT macos_version=%s\n' "${macos_version}"
  printf 'FACT macos_build=%s\n' "$(/usr/bin/sw_vers -buildVersion)"
  printf 'FACT xcode_select=%s\n' "$(/usr/bin/xcode-select -p)"
  printf 'FACT xcode=%s\n' "${xcode_version//$'\n'/; }"
  printf 'FACT swift=%s\n' "${swift_version//$'\n'/; }"
  printf 'FACT iphoneos_sdk=%s\n' "${sdk_version}"
}

verify_source() {
  local actual_commit
  local expected_commit

  expected_commit="$(<"${bootstrap_dir}/expected-commit")"
  [[ ${expected_commit} =~ ^[0-9a-f]{40}$ ]]
  actual_commit="$(/usr/bin/git -C "${repo_dir}" rev-parse HEAD)"
  [[ ${actual_commit} == "${expected_commit}" ]]
  [[ -z "$(/usr/bin/git -C "${repo_dir}" status --porcelain=v1 --untracked-files=all)" ]]
  printf 'FACT source_commit=%s\n' "${actual_commit}"
}

bootstrap() {
  local actual_sha256
  local current_system
  local installer="${bootstrap_dir}/nix-installer"
  local lock_after
  local lock_before

  verify_host
  if command -v nix >/dev/null 2>&1 || [[ -e /nix ]]; then
    printf 'error: unexpected preinstalled Nix\n' >&2
    exit 1
  fi

  /bin/rm -rf "${repo_dir}"
  /usr/bin/git clone "${bootstrap_dir}/pios.bundle" "${repo_dir}"
  /usr/bin/git -C "${repo_dir}" checkout --detach "$(<"${bootstrap_dir}/expected-commit")"
  verify_source

  /usr/bin/curl --fail --location --proto '=https' --tlsv1.2 \
    --output "${installer}" "${installer_url}"
  read -r actual_sha256 _ < <(/usr/bin/shasum -a 256 "${installer}")
  [[ ${actual_sha256} == "${installer_sha256}" ]]
  printf 'FACT installer_sha256=%s\n' "${actual_sha256}"

  /bin/chmod 0700 "${installer}"
  "${installer}" install macos --determinate --no-confirm --diagnostic-endpoint=""
  load_nix

  current_system="$(nix eval --impure --raw --expr builtins.currentSystem)"
  [[ ${current_system} == "aarch64-darwin" ]]
  printf 'FACT nix_version=%s\n' "$(nix --version)"
  printf 'FACT nix_system=%s\n' "${current_system}"

  cd "${repo_dir}"
  read -r lock_before _ < <(/usr/bin/shasum -a 256 flake.lock)
  nix develop .#remote --command /bin/bash -c \
    'set -e; command -v pi; command -v pre-commit; command -v treefmt; pi --version'
  nix develop .#remote --command make check
  read -r lock_after _ < <(/usr/bin/shasum -a 256 flake.lock)
  [[ ${lock_after} == "${lock_before}" ]]
  verify_source
  printf 'FACT flake_lock_sha256=%s\n' "${lock_after}"
}

reenter() {
  load_nix
  verify_host
  verify_source
  cd "${repo_dir}"
  nix develop .#remote --command /bin/bash -c \
    'set -e; command -v pi; printf "FACT shell_reentry=ok\\n"'
}

case "${1:-}" in
bootstrap | reenter)
  "${1}"
  ;;
*)
  printf 'usage: %s {bootstrap|reenter}\n' "$0" >&2
  exit 2
  ;;
esac
