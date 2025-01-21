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
PATH="$PATH:$HOME/.local/bin"

source ~/.aliases
