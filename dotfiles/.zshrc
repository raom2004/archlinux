#!/bin/zsh
#
# ~/.zshrc
#  user zsh shell customization
# Source:   https://raw.githubusercontent.com/MrElendig/dotfiles-alice/master/.zshrc #

#-----------------------------
# Source some stuff
#-----------------------------
# shell aliases and functions
for file in ~/.{aliases,functions}; do
  [[ -r "${file}" ]] && [[ -f "${file}" ]] && source "${file}"
done
unset file


#------------------------------
# History stuff
#------------------------------
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

#-----------------------------
# Dircolors
#-----------------------------
LS_COLORS='rs=0:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:';
export LS_COLORS

#------------------------------
# Keybindings
#------------------------------
## set global zsh keybindings
set -o emacs # or bindkey -e
# set -o vi # or bindkey -v
## set specific keybindings:
# typeset -g -A key
bindkey '^?' backward-delete-char
bindkey '^[[5~' up-line-or-history
bindkey '^[[3~' delete-char
bindkey '^[[6~' down-line-or-history
# bindkey '^[[A' up-line-or-search
bindkey '^[[D' backward-char
# bindkey '^[[B' down-line-or-search
bindkey '^[[C' forward-char 
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
#------------------------------
# zsh completion by history
#------------------------------
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# #------------------------------
# # ShellFuncs
# #------------------------------
# # -- coloured manuals
# man() {
#   env \
#     LESS_TERMCAP_mb=$(printf "\e[1;31m") \
#     LESS_TERMCAP_md=$(printf "\e[1;31m") \
#     LESS_TERMCAP_me=$(printf "\e[0m") \
#     LESS_TERMCAP_se=$(printf "\e[0m") \
#     LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
#     LESS_TERMCAP_ue=$(printf "\e[0m") \
#     LESS_TERMCAP_us=$(printf "\e[1;32m") \
#     man "$@"
# }

#------------------------------
# Comp stuff
#------------------------------
# zmodload zsh/complist 
autoload -Uz compinit && compinit
zstyle :compinstall filename '${HOME}/.zshrc'

# #- buggy
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
# #-/buggy

zstyle ':completion:*:pacman:*' force-list always
zstyle ':completion:*:*:pacman:*' menu yes select

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*'   force-list always

zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:killall:*'   force-list always


#------------------------------
# Prompt
#------------------------------
autoload -U colors zsh/terminfo && colors

# experimental:
# source: https://salferrarello.com/zsh-git-status-prompt/
# Autoload zsh add-zsh-hook and vcs_info functions (-U autoload w/o substition, -z use zsh style)
# autoload -Uz add-zsh-hook vcs_info

# Enable substitution in the prompt.
setopt prompt_subst
# Run vcs_info just before a prompt is displayed (precmd)
# add-zsh-hook precmd vcs_info
# add ${vcs_info_msg_0} to the prompt
# e.g. here we add the Git information in red  

# PROMPT='%F{cyan}%n%f@%M: %~%F{cyan}${vcs_info_msg_0_}%f %# '
source ~/.zsh_prompt

# # Enable checking for (un)staged changes, enabling use of %u and %c
# zstyle ':vcs_info:*' check-for-changes true
# # Set custom strings for an unstaged vcs repo changes (*) and staged changes (+)
# zstyle ':vcs_info:*' unstagedstr ' *'
# zstyle ':vcs_info:*' stagedstr ' +'
# # Set the format of the Git information for vcs_info
# zstyle ':vcs_info:git:*' formats       ' (%b%u%c)'
# zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
# # end


## install plugins without open vim
if [[ -f "~/.vim/plugged/jummidark.vim" ]]; then
  # create ~/.vim folder for plugin support
  url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  wget "${url}" -P /home/$USER/.vim/autoload
  ## install plugins without open vim
  vim -E -s -u $HOME/.vimrc +PlugInstall +visual +qall
fi


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
