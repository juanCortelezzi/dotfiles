#!/usr/bin/env bash
set -eo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
auth=$(mktemp -d)
echo '{}' >"$auth/auth.json"
export DOCKER_CONFIG="$auth" REGISTRY_AUTH_FILE="$auth/auth.json"
trap 'rm -rf "$auth"' EXIT

modes=("$@")
[[ ${#modes[@]} -gt 0 ]] || modes=(cold warm)
podman build -q -t dotfiles-zsh "$here" >/dev/null

status=0
for mode in "${modes[@]}"; do
  case $mode in
    cold) cache=() ;;
    warm) cache=(-v dotfiles-zsh-cache:/home/tester/.local/share) ;;
    *) echo "usage: $0 [cold] [warm]" >&2; exit 2 ;;
  esac
  echo "== $mode"
  podman run --rm --init --name "dotfiles-zsh-$mode" --hostname dotfiles-zsh \
    -e DEBUG -e ZSH_TERM \
    -v "$repo:/dotfiles:ro" ${cache[@]+"${cache[@]}"} \
    dotfiles-zsh /dotfiles/tests/zsh/entrypoint.sh bash /dotfiles/tests/zsh/scenarios.sh "$mode" || { rc=$?; (( rc == 1 )) || echo "container exited with $rc"; status=1; }
done
exit $status
