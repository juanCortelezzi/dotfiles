#!/usr/bin/env bash
set -eo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
auth=$(mktemp -d)
echo '{}' >"$auth/auth.json"
export DOCKER_CONFIG="$auth" REGISTRY_AUTH_FILE="$auth/auth.json"
trap 'rm -rf "$auth"' EXIT

cache=(-v dotfiles-zsh-cache:/home/tester/.local/share)
[[ ${1:-} == --cold ]] && cache=()
podman build -q -t dotfiles-zsh "$here" >/dev/null
podman run --rm -it --init --hostname dotfiles-zsh -e TERM="${TERM:-xterm-ghostty}" \
  -v "$repo:/dotfiles:ro" ${cache[@]+"${cache[@]}"} \
  dotfiles-zsh /dotfiles/tests/zsh/entrypoint.sh zsh -l
