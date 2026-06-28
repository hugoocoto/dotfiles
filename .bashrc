# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

set -o vi
shopt -s autocd
shopt -s cdspell
shopt -s dirspell

bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"

bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -lA --color=auto'
alias grep='grep --color=auto'
alias cd..='cd ..'
alias ga='git add .'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias za='zathura --fork'

export EDITOR='nvim'
export LESS='-R --use-color -Dd+r -Du+b'
export MANPAGER="nvim +Man!"
export MANROFFOPT="-P -c"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/code/hemp/bin"
export XDG_DATA_HOME="$HOME/.local/share"

PS1='\[\033[30;1m\]\w\[\033[0m\] '

function command_not_found_handle() {
    echo -e "\e[31m$1??\e[0m"
}

function openrepo(){
    url=$(git remote get-url origin 2>/dev/null)
    if [ -z "$url" ]; then return 1; fi
    xdg-open "$url"
}

function gc(){
    if [[ -n "$*" ]]; then
        git commit -m "$*"
    else
        git commit -e
    fi
}
