# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# Directories
# =============================================================================
for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$NVM_DIR"; do
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
done

# Convenience exports
export CONFIG="$XDG_CONFIG_HOME"
export EDITOR=nvim
export DOCKER_REGISTRY="registry.timefactory.io"
export GOPRIVATE="github.com/zachklingbeil/*,github.com/timefactoryio/*"
[[ "$TERM" == "xterm-ghostty" ]] && export TERM="xterm-256color"

# =============================================================================
# OS Specific
# =============================================================================
case "$(uname -s)" in
    Darwin*)    OS="mac" ;;
    Linux*)     OS="linux" ;;
    *)          OS="unknown" ;;
esac

# Platform-specific configuration
case "$OS" in
    mac)
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_ENV_HINTS=1
        
        typeset -U path
        path=(
            "$HOME/bin"
            "$GOBIN"
            "/opt/homebrew/bin"
            "/usr/local/sbin"
            "/usr/local/bin"
            "$NVM_DIR/bin"
            $path
        )
        
        alias up='brew update && brew upgrade && brew cleanup'
        alias mount-tf='sshfs timefactory:/home/zk ~/timefactory -o auto_cache,reconnect,defer_permissions,noappledouble,volname=timefactory'
        alias umount-tf='umount ~/timefactory'
         
        if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
            source "/opt/homebrew/opt/nvm/nvm.sh"
            [[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]] && \
                source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
        fi
        ;;
    linux)
        typeset -U path
        path=(
            "$HOME/bin"
            "$GOBIN"
            "/usr/local/sbin"
            "/usr/local/bin"
            "/usr/local/go/bin"
            "/opt/nvim-linux-x86_64/bin"
            "$NVM_DIR/bin"
            $path
        )
        
        alias up="sudo apt update && sudo apt upgrade -y && sudo apt autoremove && sudo apt autoclean"
        alias sus="sudo systemctl "
        alias bt="btop"
        
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
        ;;
esac

# =============================================================================
# ZSH
# =============================================================================
export ZSH="$ZDOTDIR/oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
export HISTFILE="$ZDOTDIR/data/.zsh_history"
export ZSH_COMPDUMP="$ZDOTDIR/data/.zcompdump"

# History settings
export HISTSIZE=1000
export SAVEHIST=1000
setopt appendhistory
setopt sharehistory
autoload -U compinit && compinit
HIST_STAMPS="%m.%d.%Y %H:%M:%S.%3N"

# Oh My Zsh settings
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode reminder
CASE_SENSITIVE="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"
DISABLE_AUTO_TITLE="true"

# Plugins
plugins=(
  git
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# Aliases
# =============================================================================
alias zed="sudo nvim $ZDOTDIR/.zshrc"
alias zeds="source $ZDOTDIR/.zshrc"
alias .="sudo $EDITOR"
alias .c="cd $CONFIG"
alias .n="cd $CONFIG/nvim/lua"

alias ..="cd .."
alias ls="lsd"
alias ll="lsd -a"
alias lg="lazygit"
alias ld="lazydocker"

alias gmt="go mod tidy"
alias gogo='go run main.go'
alias ggg='go get -u ./...'
# =============================================================================
# Functions
# =============================================================================
mkd() {
    mkdir -p "$1" && cd "$1"
}

dx() {
  case $1 in
    geth) docker exec -it geth geth ;;
    redis) docker exec -it redis redis-cli ;;
    postgres) docker exec -it postgres psql -U postgres ;;
    *) echo "Usage: dx {geth|redis|postgres} [args...]" ;;
  esac
}

dxx() {
    docker exec -it $1 /bin/sh
}

dc() {
  case $1 in
    d) docker compose down ;;
    c) docker compose up ;;
    *) docker compose up -d ;;
  esac
}

# Docker resource management (CRUD operations)
dd() {
  case $1 in
    n) # docker network
      case $2 in
        i) docker network inspect "${@:3}" ;;
        c) docker network create "${@:3}" ;;
        r) docker network rm "${@:3}" ;;
        *) docker network ls ;;
      esac
      ;;
    v) # docker volume
      case $2 in
        i) docker volume inspect "${@:3}" ;;
        c) docker volume create "${@:3}" ;;
        r) docker volume rm "${@:3}" ;;
        *) docker volume ls ;;
      esac
      ;;
    i) # docker image
      case $2 in
        i) docker image inspect "${@:3}" ;;
        r) docker image rm "${@:3}" ;;
        *) docker image ls ;;
      esac
      ;;
    c) # docker context
      case $2 in
        i) docker context inspect "${@:3}" ;;
        c) docker context create "${@:3}" ;;
        r) docker context rm "${@:3}" ;;
        *) docker context ls ;;
      esac
      ;;
    I) docker info ;;
    *) docker ps -a --format "table {{.Image}}\t{{.Names}}\t{{.Status}}" ;;
  esac
}

# Docker build with multi-platform support
db() {
    docker buildx build --platform linux/amd64,linux/arm64 -t $DOCKER_REGISTRY/$1 . --push
}

# =============================================================================
# Load P10k Configuration
# =============================================================================
[[ ! -f "$ZDOTDIR/.p10k.zsh" ]] || source "$ZDOTDIR/.p10k.zsh"