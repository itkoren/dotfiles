#!/bin/bash

# Keep 10,000,000 lines of history within the shell and save it to ~/.zsh_history:
export HISTSIZE=10000000
export SAVEHIST=10000000
export HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
