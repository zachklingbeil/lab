#!/bin/sh

# Ensure /usr/local/go/bin is in PATH for the current session 
case ":$PATH:" in
  *:/usr/local/go/bin:*) ;;
  *) export PATH="$PATH:/usr/local/go/bin" ;;
esac

# Check for current go version, exit if already up to date, or install the latest version
CURRENT=$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}' || echo "none")
LATEST=$(curl -s "https://go.dev/VERSION?m=text" | grep -o 'go[0-9.]*') || { echo "Failed to fetch the latest go version."; exit 1; }
DOWNLOAD="https://go.dev/dl/${LATEST}.linux-amd64.tar.gz"

if [ "$CURRENT" = "$LATEST" ]; then
  echo "already up to date"
  echo "$(/usr/local/go/bin/go version)"
else
  # Remove the previous installation then download/extract the latest version
  if sudo rm -rf /usr/local/go && wget -qO- "$DOWNLOAD" | sudo tar -C /usr/local -xzf -; then
    echo "$LATEST installed successfully."
  else
    echo "Failed to download or extract go $LATEST."
    exit 1
  fi
fi