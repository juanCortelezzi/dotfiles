ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"

#------------------------------------------------------------------------------
setopt no_beep              # No beep
setopt numeric_glob_sort    # Sort filenames numerically when it makes sense
# setopt extended_glob      # Enable zsh extended glob patterns

setopt extended_history       # Save timestamp of commands on history
setopt inc_append_history     # Save commands are added to the history immediately, otherwise only when shell exits
setopt hist_ignore_all_dups   # If a new command is a duplicate, remove the older one
setopt hist_expire_dups_first # Expire duplicates first when trimming history
setopt hist_verify            # Don't execute immediately on history expansion
setopt hist_reduce_blanks     # Remove extra blanks from commands
unsetopt share_history        # I don't like sharing history across tmux panes

ZSH_CACHE_HOME="$XDG_CACHE_HOME/zsh"
mkdir -p "$ZSH_CACHE_HOME"
HISTFILE="$ZSH_CACHE_HOME/zhistory"
HISTSIZE=50000
SAVEHIST=50000

# Edit line in editor with ctrl-e:
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^k" up-line-or-beginning-search # Up
bindkey "^j" down-line-or-beginning-search # Down

# Completions
ZCOMPDUMP="$ZSH_CACHE_HOME/zcompdump"
# autoload -Uz compinit
# if () {
#     setopt localoptions extended_glob
#     [[ -n  "$ZCOMPDUMP"(#qN.mh+24) ]]
# }; then
#     compinit -d "$ZCOMPDUMP"
# else
#     compinit -C -d "$ZCOMPDUMP"
# fi

zmodload zsh/complist
_comp_options+=(globdots) # Show dotfiles on completion

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_HOME/.zcache"

zinit wait lucid light-mode for \
  atload"!_zsh_autosuggest_start" zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' zsh-users/zsh-completions \
  as"program" from"gh-r" pick"zsh-patina-*/zsh-patina" atinit="ZINIT[ZCOMPDUMP_PATH]=$ZCOMPDUMP zicompinit; zicdreplay" atload'eval "$(zsh-patina activate)"' michel-kraemer/zsh-patina

if [ -f "$ZDOTDIR/zsh-aliases" ]; then
  source "$ZDOTDIR/zsh-aliases"
fi

if [ -f "$ZDOTDIR/zsh-prompt" ]; then
  source "$ZDOTDIR/zsh-prompt"
fi

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# zoxide hook
if command -v -- "zoxide" > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# direnv hook
if command -v -- "direnv" > /dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi
