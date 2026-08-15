#!/usr/bin/env bash
set -Eeuo pipefail

export LC_ALL=C
umask 077

readonly machine_type="macos/arm64:6x14"
readonly selectors="macos.version=26.x,image.with=xcode-26"
readonly duration="2h"

for command_name in git nsc; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'error: required command is missing: %s\n' "${command_name}" >&2
    exit 1
  fi
done

repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

if [[ -n "$(git status --porcelain=v1 --untracked-files=all)" ]]; then
  printf 'error: the source worktree must be clean\n' >&2
  exit 1
fi

commit="$(git rev-parse --verify HEAD)"
[[ ${commit} =~ ^[0-9a-f]{40}$ ]]
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
unique_tag="pios-macos-${commit:0:12}-${run_id}"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/pios-namespace.XXXXXXXX")"
instance_id=""

find_managed_instances() {
  nsc list --output json --label="run-id=${run_id}" |
    sed -n 's/^[[:space:]]*"cluster_id": "\([^"]*\)",*$/\1/p'
}

cleanup() {
  local original_status=$?
  local cleanup_status=0
  local candidate=""
  local matches=""
  local remaining=""

  trap - EXIT HUP INT TERM
  set +e

  matches="${instance_id:-$(find_managed_instances)}"
  if [[ -n ${matches} ]]; then
    if [[ ${matches} == *$'\n'* ]]; then
      printf 'error: multiple instances match run-id %s; refusing ambiguous cleanup\n' "${run_id}" >&2
      cleanup_status=1
    else
      candidate="${matches}"
      printf 'CLEANUP destroying instance=%s\n' "${candidate}"
      if ! nsc destroy --force "${candidate}"; then
        cleanup_status=1
      else
        for _ in {1..12}; do
          remaining="$(find_managed_instances)"
          [[ -z ${remaining} ]] && break
          sleep 5
        done
        if [[ -n ${remaining} ]]; then
          printf 'error: managed instance remains after destroy: %s\n' "${remaining}" >&2
          cleanup_status=1
        else
          printf 'CLEANUP confirmed no instance for run-id=%s\n' "${run_id}"
        fi
      fi
    fi
  else
    printf 'CLEANUP no instance found for run-id=%s\n' "${run_id}"
  fi

  rm -rf "${temp_dir}"
  ((original_status == 0)) || exit "${original_status}"
  exit "${cleanup_status}"
}
trap cleanup EXIT HUP INT TERM

git bundle create "${temp_dir}/pios.bundle" HEAD
git bundle verify "${temp_dir}/pios.bundle"
printf '%s\n' "${commit}" >"${temp_dir}/expected-commit"

printf 'REQUEST run_id=%s\n' "${run_id}"
printf 'REQUEST commit=%s\n' "${commit}"
printf 'REQUEST machine_type=%s\n' "${machine_type}"
printf 'REQUEST selectors=%s\n' "${selectors}"
printf 'REQUEST duration=%s\n' "${duration}"

nsc create \
  --bare \
  --machine_type="${machine_type}" \
  --selectors="${selectors}" \
  --duration="${duration}" \
  --wait_timeout=10m \
  --purpose="pios macOS development host spike" \
  --unique_tag="${unique_tag}" \
  --label="managed-by=pios-namespace-spike" \
  --label="project=pios" \
  --label="role=development" \
  --label="source-commit=${commit}" \
  --label="run-id=${run_id}" \
  --cidfile="${temp_dir}/instance-id" \
  --output_json_to="${temp_dir}/instance.json"

instance_id="$(<"${temp_dir}/instance-id")"
[[ ${instance_id} =~ ^[a-z0-9]+$ ]]
deadline="$(sed -n 's/^[[:space:]]*"deadline": "\([^"]*\)",*$/\1/p' "${temp_dir}/instance.json")"
printf 'INSTANCE id=%s deadline=%s\n' "${instance_id}" "${deadline}"

nsc instance upload --mkdir "${instance_id}" "${temp_dir}/pios.bundle" \
  /var/tmp/pios-bootstrap/pios.bundle
nsc instance upload --mkdir "${instance_id}" "${repo_root}/tools/namespace-spike-remote.sh" \
  /var/tmp/pios-bootstrap/remote.sh
nsc instance upload --mkdir "${instance_id}" "${temp_dir}/expected-commit" \
  /var/tmp/pios-bootstrap/expected-commit

nsc ssh --disable-pty "${instance_id}" \
  "/bin/bash /var/tmp/pios-bootstrap/remote.sh bootstrap"
nsc ssh --disable-pty "${instance_id}" \
  "/bin/bash /var/tmp/pios-bootstrap/remote.sh reenter"
printf 'RESULT namespace spike succeeded instance=%s\n' "${instance_id}"
