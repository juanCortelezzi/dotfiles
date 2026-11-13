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

autoload -Uz edit-command-line up-line-or-beginning-search down-line-or-beginning-search
zle -N edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^e' edit-command-line
bindkey '^k' up-line-or-beginning-search
bindkey '^j' down-line-or-beginning-search

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
