#!/bin/sh
set -e
stow -d /dotfiles -t "$HOME" zsh
exec "$@"
