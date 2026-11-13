setopt no_beep
setopt numeric_glob_sort

setopt extended_history
setopt inc_append_history
setopt hist_ignore_all_dups
setopt hist_expire_dups_first
setopt hist_verify
setopt hist_reduce_blanks
unsetopt share_history

ZSH_CACHE_HOME="$XDG_CACHE_HOME/zsh"
ZSH_PLUGIN_HOME="$XDG_DATA_HOME/zsh/plugins"
[[ -d $ZSH_CACHE_HOME ]] || mkdir -p "$ZSH_CACHE_HOME"
HISTFILE="$ZSH_CACHE_HOME/zhistory"
HISTSIZE=50000
SAVEHIST=50000

missing_plugins=()
if [[ -d $ZSH_PLUGIN_HOME/zsh-completions/src ]]; then
  fpath=("$ZSH_PLUGIN_HOME/zsh-completions/src" $fpath)
else
  missing_plugins+=zsh-completions
fi
if [[ -x $ZSH_PLUGIN_HOME/zsh-patina/zsh-patina ]]; then
  fpath=("$ZSH_PLUGIN_HOME/zsh-patina/completion" $fpath)
else
  missing_plugins+=zsh-patina
fi

zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_HOME/.zcache"
autoload -Uz compinit
compinit -d "$ZSH_CACHE_HOME/zcompdump-$ZSH_VERSION"
_comp_options+=(globdots)

[[ -f $ZDOTDIR/zsh-aliases ]] && source "$ZDOTDIR/zsh-aliases"
[[ -f $ZDOTDIR/zsh-prompt ]] && source "$ZDOTDIR/zsh-prompt"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

bindkey -v
KEYTIMEOUT=1

autoload -Uz add-zle-hook-widget edit-command-line up-line-or-beginning-search down-line-or-beginning-search
zle -N edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

ignore-key() {}
zle -N ignore-key

for keymap in viins vicmd; do
  bindkey -M $keymap '^?' backward-delete-char
  bindkey -M $keymap '^H' backward-delete-char
  bindkey -M $keymap '^M' accept-line
  bindkey -M $keymap '^K' up-line-or-beginning-search
  bindkey -M $keymap '^J' down-line-or-beginning-search
  bindkey -M $keymap '^E' edit-command-line
  bindkey -M $keymap '\e[A' up-line-or-beginning-search
  bindkey -M $keymap '\eOA' up-line-or-beginning-search
  bindkey -M $keymap '\e[B' down-line-or-beginning-search
  bindkey -M $keymap '\eOB' down-line-or-beginning-search
  bindkey -M $keymap '\e[C' vi-forward-char
  bindkey -M $keymap '\eOC' vi-forward-char
  bindkey -M $keymap '\e[D' vi-backward-char
  bindkey -M $keymap '\eOD' vi-backward-char
  bindkey -M $keymap '\e[I' ignore-key
  bindkey -M $keymap '\e[O' ignore-key
done
unset keymap

cursor-shape() {
  [[ $KEYMAP == vicmd ]] && print -n '\e[2 q' || print -n '\e[6 q'
}
cursor-reset() {
  print -n '\e[0 q'
}
add-zle-hook-widget line-init cursor-shape
add-zle-hook-widget keymap-select cursor-shape
add-zle-hook-widget line-finish cursor-reset

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
if [[ -f $ZSH_PLUGIN_HOME/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source "$ZSH_PLUGIN_HOME/zsh-autosuggestions/zsh-autosuggestions.zsh"
else
  missing_plugins+=zsh-autosuggestions
fi

[[ -x $ZSH_PLUGIN_HOME/zsh-patina/zsh-patina ]] && eval "$("$ZSH_PLUGIN_HOME/zsh-patina/zsh-patina" activate)"

(( $#missing_plugins )) && print -ru2 -- "zsh: missing ${(j:, :)missing_plugins}, run: \$ZDOTDIR/zsh-plugins install"
unset missing_plugins
