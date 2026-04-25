setopt no_beep              # No beep
setopt numeric_glob_sort    # Sort filenames numerically when it makes sense
# setopt extended_glob      # Extended globbing. Allows using regular expressions with *

setopt extended_history       # Save timestamp of commands on history
setopt inc_append_history     # Save commands are added to the history immediately, otherwise only when shell exits.
setopt hist_ignore_all_dups   # If a new command is a duplicate, remove the older one
setopt hist_expire_dups_first # Expire duplicates first when trimming history
setopt hist_verify            # Don't execute immediately on history expansion
setopt hist_reduce_blanks     # Remove extra blanks from commands

mkdir -p "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_CACHE_HOME/zsh/zhistory"
HISTSIZE=50000
SAVEHIST=50000

# autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
autoload -Uz compinit
if [[ -n "$XDG_CACHE_HOME/zsh/zcompdump"(#qN.mh+24) ]]; then
    echo "Path A"
    compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
else
    echo "Path B"
    compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi

# Edit line in editor with ctrl-e:
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^k" up-line-or-beginning-search # Up
bindkey "^j" down-line-or-beginning-search # Down

zmodload zsh/complist
_comp_options+=(globdots) # Show dotfiles on completion

# Speed up completions
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcache"

# Useful funcions
source "$ZDOTDIR/zsh-functions"

# Load aliases and shortcuts if existent.
zsh_add_file "$ZDOTDIR/zsh-aliases"
zsh_add_file "$ZDOTDIR/zsh-prompt"

# Load pluggins
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern regexp)

typeset -A ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=magenta,bold'

ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=9'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=9'
ZSH_HIGHLIGHT_STYLES[path]='fg=yellow,underline'
ZSH_HIGHLIGHT_STYLES[unknown-token]='none'

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"

# start ssh-agent
# if ! pgrep -u "$USER" ssh-agent > /dev/null; then
#     ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
# fi

# if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
#     source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
# fi

if command -v -- "zoxide" > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# direnv hook
if command -v -- "direnv" > /dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# bun completions
# [ -s "$XDG_CONFIG_HOME/bun/_bun" ] && source "$XDG_CONFIG_HOME/bun/_bun"

# Opam init shit
# [[ ! -r "$XDG_DATA_HOME/opam/opam-init/init.zsh" ]] || source "$XDG_DATA_HOME/opam/opam-init/init.zsh"  > /dev/null 2> /dev/null

# SDKman init
# [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
