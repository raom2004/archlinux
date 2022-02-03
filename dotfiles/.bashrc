#!/bin/bash
#
# ~/.bashrc
# All the customizations related to bash shell

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# Colorcoding
NBlack='\[\e[0;30m\]'   
NRed='\[\e[0;31m\]'
NGreen='\[\e[0;32m\]'
NYellow='\[\e[0;33m\]'
NBlue='\[\e[0;34m\]'
NPurple='\[\e[0;35m\]'
NCyan='\[\e[0;36m\]'
NWhite='\[\e[0;37m\]'

# Bold
BBlack='\[\e[1;30m\]'
BRed='\[\e[1;31m\]'
BGreen='\[\e[1;32m\]'
BYellow='\[\e[1;33m\]'
BBlue='\[\e[1;34m\]'
BPurple='\[\e[1;35m\]'
BCyan='\[\e[1;36m\]'
BWhite='\[\e[1;37m\]'

# Background
On_Black='\[\e[40m\]'
On_Red='\[\e[41m\]'
On_Green='\[\e[42m\]'
On_Yellow='\[\e[43m\]'
On_Blue='\[\e[44m\]'
On_Purple='\[\e[45m\]'
On_Cyan='\[\e[46m\]'
On_White='\[\e[47m\]'

# Color Reset
NC='\[\e[m\]'

# Bold White on red background
ALERT="${BWhite}${On_Red}"

### PERSONAL CUSTOMIZATION ###########################################
# inspired by: https://serverfault.com/questions/3743/what-useful-things-can-one-add-to-ones-bashrc
# https://github.com/mathiasbynens/dotfiles/blob/main/.bash_profile

## PROMPT, aliases and functions
for file in ~/.{bash_prompt,aliases,functions,inputrc}; do
  [[ -r "${file}" ]] && [[ -f "${file}" ]] && source "${file}"
done
unset file

# SPELLING: fix spelling errors for cd
shopt -s cdspell

## HISTORY CONFIGURATION ##############################################

shopt -s histappend   # append instead of overwrite it
shopt -s cmdhist      # Combine multiline commands into one in history

# Ignore duplicates, ls without options and builtin commands
HISTCONTROL=ignoredups

export HISTIGNORE="&:ls:[bf]g:exit"
export HISTFILESIZE=20000
export HISTSIZE=10000


# shell command not found
source /usr/share/doc/pkgfile/command-not-found.bash
# can be also activated by /etc/bash.bashrc


## set command-line keybindings
# set -o emacs 			# stardand option in bash
# set -o vi

## bash key shortcuts
# source: https://gist.github.com/tuxfight3r/60051ac67c5f0445efee


## install plugins without open vim
if [[ ! -f "~/.vim/plugged/jummidark.vim" ]]; then
  # create ~/.vim folder for plugin support
  url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  wget "${url}" -P /home/$USER/.vim/autoload
  ## install plugins without open vim
  vim -E -s -u $HOME/.vimrc +PlugInstall +visual +qall
fi


## git config
if [[ -f "/run/media/$USER/TOSHIBA_EXT/.gitrc" ]]; then
  git config --global -f "/run/media/$USER/TOSHIBA_EXT/.gitrc"
fi


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
