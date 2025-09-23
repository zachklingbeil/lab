# Set XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Set ZDOTDIR to use XDG config directory for ZSH
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Editor configuration
export EDITOR=nvim
export VISUAL="$EDITOR"
export PAGER=less

# Git XDG configuration
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"

# Docker configuration
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Go XDG configuration  
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$GOPATH/bin"

# Node/NPM XDG configuration
export NVM_DIR="$XDG_CONFIG_HOME/nvm"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
