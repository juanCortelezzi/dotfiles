# XDG Base Directory Specification
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_STATE_HOME=${XDG_STATE_HOME:="$HOME/.local/state"}

# zsh config
ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export LANG=en_US.UTF-8
export TERMINAL="ghostty"
export VISUAL="nvim"
export EDITOR="nvim"
export BROWSER="zen-browser"

# add npm globals to path (Node, Bun, Deno, JS, TS, etc)
# export NPM_CONFIG_PREFIX="$XDG_CONFIG_HOME/npm/npm-global"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
# export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
export VOLTA_HOME="$XDG_CONFIG_HOME/volta"
export PATH="$VOLTA_HOME/bin:$PATH"
# add bun to path
export BUN_INSTALL="$XDG_CONFIG_HOME/bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# add haskell to path (Haskell)
# export CABAL_CONFIG="$XDG_CONFIG_HOME/cabal/config"
# export GHCUP_USE_XDG_DIRS=true # set to anything

# add cargo/rust to path (Rust)
export RUSTUP_HOME="$XDG_CONFIG_HOME/rust/rustup"
export CARGO_HOME="$XDG_DATA_HOME/rust/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# add opam to path (OCaml)
export OPAMROOT="$XDG_DATA_HOME/opam"

# add go to path (Go)
export GOPATH="$XDG_DATA_HOME/golang/gopath"
export PATH="$GOPATH/bin:$PATH"

# Java
export SDKMAN_DIR="$XDG_DATA_HOME/sdkman"

# enabel mix xdg directories (Elixir)
export MIX_XDG=1

# Ansible
# export ANSIBLE_HOME="$XDG_CONFIG_HOME/ansible"
# pass password storage
export PASSWORD_STORE_DIR="$XDG_CONFIG_HOME/pass-store"
# gtk2rc to .config for ancient applications
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
# gnupg to .config
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
# remove docker from home dir
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
# remove android from home dir
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
# No hist file
export LESSHISTFILE="-"
# move sqlite history
export SQLITE_HISTORY="$XDG_CACHE_HOME/sqlite_history"
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

