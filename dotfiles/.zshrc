#!/bin/zsh
#
# ~/.zshrc
#  user zsh shell customization
# inspired in code:
#https://raw.githubusercontent.com/MrElendig/dotfiles-alice/master/.zshrc
#
### CODE:

### SOURCE REQUIRED CONFIG

for file in ~/.{aliases,functions}; do
  [[ -r "${file}" ]] && [[ -f "${file}" ]] && source "${file}"
done
unset file


### HISTORY CONFIG

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000


### DIRCOLORS
LS_COLORS='rs=0:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:';
export LS_COLORS


### KEYBINDINGS

## set global zsh keybindings
set -o emacs    # or: bindkey -e
# set -o vi     # or: bindkey -v
## set specific keybindings
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


### ZSH COMPLETION BY HISTORY

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end


### CUSTOMIZED COMPLETION OPTIONS

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


### ZSH PROMPT

source ~/.zsh_prompt


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
