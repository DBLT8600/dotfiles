if (( ${DEBUG:=0} )); then
    ZPROF=1
    set -x
fi

if (( ${ZPROF:=0} )); then
    zmodload zsh/zprof; zprof
fi

if (( $+commands[tmux] && ! $+TMUX && $+SSH_CONNECTION )); then
    tmux has -t ssh && exec tmux attach -t ssh
    exec tmux new -s ssh
fi

bindkey -e

ttyctl -f

typeset -U path
path+=(~/bin(N-/) ~/.local/bin(N-/))

typeset -U cdpath
cdpath+=(~)

HISTFILE=/dev/null
HISTSIZE=1000

if [[ $TERM == linux ]]; then
    return 0
fi

# Completion

# Glob
setopt EXTENDED_GLOB
setopt NULL_GLOB

# History
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

export HISTFILE=~/.zsh_history
export SAVEHIST=100000
export HISTSIZE=$((SAVEHIST + 1))

alias history='fc -dl -t "%Y-%m-%d %H:%M:%S"'

typeset -U hist_ignore
hist_ignore=(history fc)
export HISTORY_IGNORE="(${(j:|:)hist_ignore})"

# Do not add failed commands to history
zshaddhistory() {
    typeset -g LASTCMD=${1%%$'\n'}; return 1
}

save_successful_command_to_history() {
    local -i rc=$?
    if (( $rc == 0 && $+LASTCMD && $#LASTCMD )); then
        builtin print -rs -- $LASTCMD
    fi
    unset LASTCMD
}

precmd_functions+=(save_successful_command_to_history)

bindkey  history-incremental-pattern-search-backward
bindkey  history-incremental-pattern-search-forward
bindkey  history-beginning-search-backward
bindkey  history-beginning-search-forward

# Delimiter
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars ' /=;@:{}[]()<>,|.'
zstyle ':zle:*' word-style unspecified

# Dotfiles
DOTFILES_GIT_DIR=~/.dotfiles
DOTFILES_WORK_TREE=~

alias dotfiles='git --git-dir $DOTFILES_GIT_DIR --work-tree $DOTFILES_WORK_TREE'

if [[ ! -d $DOTFILES_GIT_DIR ]]; then
    dotfiles init
fi

dotfiles-auto-commit() {
    local a x y f m
    for a in "${(@)$(dotfiles status -s)}"; do
        x=${a:0:1} y=${a:1:1} f=${a:3} m=''
        case "$x$y" in
            A*) m="add $f" ;;
            M*|' 'M) m="update $f" ;;
            D*|' 'D) m="delete $f" ;;
            C*|' 'C) echo "copy $f" ;;
            R*|' 'R) echo "rename $f" ;;
        esac
        if [[ -n $m ]]; then
            dotfiles commit -m "$m" "$f"
        fi
    done
}

autoload -Uz compinit
compinit

compdef dotfiles=git

# Useful functions
mkcd() { install -Dd "$1" && cd "$1" }

mkpw() { < /dev/random tr -dc "${2:-A-Za-z0-9}" | head -c ${1:-10}; echo }

reset_broken_terminal() { printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8' }
precmd_functions+=(reset_broken_terminal)

clear_screen_and_scrollback() { printf '\x1Bc'; zle clear-screen }
zle -N clear_screen_and_scrollback
bindkey  clear_screen_and_scrollback

# Useful aliases
alias relogin='exec $SHELL -l'
alias ls='ls -Xv --color=auto --group-directories-first'

# Znap
# Znap! Fast, easy-to-use tools for Zsh dotfiles & plugins, plus git repos
# https://github.com/marlonrichert/zsh-snap

[[ -r ~/.znap/znap.zsh ]] \
    || git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/.znap

source ~/.znap/znap.zsh

zstyle ':znap:*' repos-dir ~/.znap/repos

# xhange the symbol for both `prompt` and `vicmd`
PURE_PROMPT_SYMBOL='›'
PURE_PROMPT_VICMD_SYMBOL='‹'

# turn on git stash status
zstyle ':prompt:pure:git:stash' show yes

# change the color for both `prompt:success` and `prompt:error`
zstyle ':prompt:pure:prompt:success' color green
zstyle ':prompt:pure:prompt:error' color red

# Pretty, minimal and fast ZSH prompt.
znap prompt sindresorhus/pure

# Additional completion definitions for Zsh.
znap clone zsh-users/zsh-completions
fpath+=(~[zsh-users/zsh-completions]/src)

# Fish shell like syntax highlighting for Zsh.
znap source zsh-users/zsh-syntax-highlighting

# Fish-like autosuggestions for zsh.
znap source zsh-users/zsh-autosuggestions

# zsh anything.el-like widget.
znap source zsh-users/zaw

# Displays installation information for not found commands.
# Arch Linux: pkgfile
# macOS: brew
znap source sorin-ionescu/prezto modules/command-not-found

if (( $+commands[emacsclient] )); then
    alias emacs='emacsclient -t'
fi

if (( $+commands[gpg] )); then
    if [[ "${gnupg_SSH_AUTH_SOCK_by:-0}" != $$ ]]; then
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    fi

    export GPG_TTY=$(tty)

    gpg-connect-agent updatestartuptty /bye >/dev/null
fi

if (( $+commands[ssh] && $+SSH_AUTH_SOCK )); then
    alias ssh='ssh-add -l >/dev/null || ssh-add && unalias ssh; ssh'
fi

if (( $+commands[nnn] )); then
    export NNN_OPTS=adoRSU
fi

if (( $+commands[pass] )); then
    export PASSWORD_STORE_ENABLE_EXTENSIONS=true
fi

if (( $+commands[vim] )); then
    export EDITOR=vim
fi

() {
    local src=$1 zwc=$1.zwc
    [[ -n $src ]] || return 0
    if [[ ! -f $zwc || $src -nt $zwc ]]; then
        zcompile $src
    fi
    source $src
} ~/.zshrc.*~*.zwc~*\~

if (( $ZPROF )); then
    set +x
    zprof
fi
