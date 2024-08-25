# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -d ~/afs/bin ] ; then
	export PATH=~/afs/bin:$PATH
fi

if [ -d ~/.local/bin ] ; then
	export PATH=~/.local/bin:$PATH
fi

export LANG=en_US.utf8
export NNTPSERVER="news.epita.fr"

export EDITOR=nvim
#export EDITOR=emacs

# Color support for less
#export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
#export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
#export LESS_TERMCAP_me=$'\E[0m'           # end mode
#export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
#export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
#export LESS_TERMCAP_ue=$'\E[0m'           # end underline
#export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

#Customization
# vim Vianney
export PATH="/run/current-system/sw/bin/clangd:$PATH"

alias ls='ls --color=auto'
alias gs='git status --porcelain'
alias grep='grep --color -n'
alias la='ls -a'
alias makeshortcut="ln -s"
alias here="pwd | xsel -b"
alias copy="xsel -b"

function touchScript(){
    if [ $# -ne 1 ]; then
        echo "Wrong arg number"
        exit 1
    else
        printf '#!/bin/sh\n\n\n' > "$1"
        chmod u+x "$1"
    fi
}

function touchHeader(){
    printf "#ifndef MY_HEADER_FILENAME_H\n\
#define MY_HEADER_FILENAME_H\n\
\n\
#endif\n" > $1.h
}

alias confs="cd ~/afs/.confs"
alias vim='nvim'

alias acdc='cd ~/Documents/School/ING-EPITA/ING1/ACDC'
alias epita='cd ~/Documents/School/ING-EPITA/ING1'
alias psc='cd ~/Documents/School/ING-EPITA/ING1/CNIX/piscine-2026-lucas.duport'

alias format='find . -iname "*.h" -o -iname "*.c" | xargs clang-format -i'
alias formatCheck='python3 ~/afs/ING/coding-style/moulinette.py'
alias netticheck='~/afs/ING/netiquette_checker/leodagan.py -vv'
alias autoTag='~/Scripts/autoTag.sh'
alias touchMakefile='cp ~/Scripts/genericMakefile $(pwd)/Makefile'
alias touchHeader='cp ~/afs/.confs/genericHeader $(pwd)/header.h'
alias touchTests='mkdir -p tests; cp ~/afs/.confs/tests.c tests/'
alias wrapImg='convert -scale 1920x1080 -gravity center'
alias cleanRam='# sync; echo 1 > /proc/sys/vm/drop_caches'
alias newEx='python3 ~/Scripts/newExercise.py'
alias folderSize='du -hd 1'
alias gdb='gdb -tui'
alias resource='source ~/.bashrc'
alias myfind='~/Documents/School/ING-EPITA/ING1/CNIX/myfind-2026-lucas.duport/myfind/myfind'

# Rebinds capslock to escape
setxkbmap -option caps:escape

# PS1
PROMPT_COMMAND=__prompt_command    # Function to generate PS1 after CMDs

__prompt_command() {
    local EXIT="$?"                # This needs to be first
    PS1=""

    local RCol='\[\e[0m\]'

    local Red='\[\e[0;31m\]'
    local Gre='\[\e[0;32m\]'
    local BYel='\[\e[1;33m\]'
    local BBlu='\[\e[1;34m\]'
    local Pur='\[\e[0;35m\]'

    if [ $EXIT != 0 ]; then
        PS1+="${Red}[$EXIT]${RCol}"        # Add red if exit code non 0
    else
        PS1+="${Gre}[$EXIT]${RCol}"
    fi

    PS1+=" ${Pur}[..\${PWD#\${PWD%/*/*}}]${Rcol} ${BYel}> ${RCol}"
}
export PGDATA="$HOME/postgres_data"
export PGHOST="/tmp"
export PGDATA="$HOME/postgres_data"
export PGHOST="/tmp"
