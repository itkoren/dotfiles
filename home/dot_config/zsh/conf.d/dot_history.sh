#!/bin/bash

setopt EXTENDED_HISTORY   # enable more detailed history (time, command, etc.)   
setopt SHARE_HISTORY      # share history across multiple zsh sessions
setopt APPEND_HISTORY     # append to history
setopt INC_APPEND_HISTORY # adds commands as they are typed, not at shell exit
setopt HIST_VERIFY        # let you edit !$, !! and !* before executing the command
setopt HIST_IGNORE_DUPS   # do not store duplications
setopt HIST_REDUCE_BLANKS # removes blank lines from history

# Keep 10,000,000 lines of history within the shell and save it to ~/.zsh_history:
export HISTSIZE=10000000
export SAVEHIST=10000000
export HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history

export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"

bindkey '^f' atuin-search

# bind to the up key, which depends on terminal mode
bindkey '^[[A' atuin-up-search
bindkey '^[OA' atuin-up-search
