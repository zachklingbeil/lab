#!/usr/bin/env bash
# Universal Go update script for macOS and Linux

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names to Go's naming convention
case "$ARCH" in
x86_64)
	GO_ARCH="amd64"
	;;
arm64 | aarch64)
	GO_ARCH="arm64"
	;;
*)
	echo "Unsupported architecture: $ARCH"
	exit 1
	;;
esac

# Map OS names to Go's naming convention
case "$OS" in
darwin)
	GO_OS="darwin"
	;;
linux)
	GO_OS="linux"
	;;
*)
	echo "Unsupported operating system: $OS"
	exit 1
	;;
esac

echo "Detected platform: ${GO_OS}-${GO_ARCH}"

# Fetch the latest Go version
LATEST=$(curl -s "https://go.dev/VERSION?m=text" | grep -o 'go[0-9.]*') || {
	echo "Failed to fetch the latest Go version."
	exit 1
}

# Check if Go is already installed and up to date
if command -v go >/dev/null 2>&1; then
	CURRENT=$(go version | awk '{print $3}')
	if [ "$CURRENT" = "$LATEST" ]; then
		echo "Go is already up to date: $(go version)"
		exit 0
	fi
	echo "Updating Go from $CURRENT to $LATEST"
else
	echo "Installing Go $LATEST"
fi

DOWNLOAD="https://go.dev/dl/${LATEST}.${GO_OS}-${GO_ARCH}.tar.gz"

# Remove the previous installation if it exists
sudo rm -rf /usr/local/go

# Download and install the latest version
echo "Downloading $LATEST for ${GO_OS}-${GO_ARCH}..."
if curl -LO "$DOWNLOAD" && sudo tar -C /usr/local -xzf "${LATEST}.${GO_OS}-${GO_ARCH}.tar.gz"; then
	echo "$LATEST installed successfully."
	# Clean up the downloaded archive
	rm -f "${LATEST}.${GO_OS}-${GO_ARCH}.tar.gz"
else
	echo "Failed to download or install Go $LATEST."
	exit 1
fi

echo "Go update complete: $(go version)"

