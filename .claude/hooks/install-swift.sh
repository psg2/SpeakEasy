#!/bin/bash
set -e

# Only run in sandbox environment (Claude Code Web)
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  echo "Skipping Swift installation - running locally"
  exit 0
fi

echo "Setting up Swift in sandbox environment..."

# Check if Swift is already installed
if command -v swift &> /dev/null; then
  echo "Swift is already installed: $(swift --version)"
  exit 0
fi

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Convert architecture names to Swift's naming convention
case "$ARCH" in
  x86_64)
    SWIFT_ARCH="x86_64"
    ;;
  aarch64|arm64)
    SWIFT_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 2
    ;;
esac

# Download and install Swift for Ubuntu (sandbox typically runs Ubuntu)
if [ "$OS" = "linux" ]; then
  # Use Swift 5.9.2 for Ubuntu 22.04 (adjust version as needed)
  SWIFT_VERSION="5.9.2"
  SWIFT_PLATFORM="ubuntu2204"
  SWIFT_PACKAGE="swift-${SWIFT_VERSION}-RELEASE-${SWIFT_PLATFORM}"
  SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2204/swift-${SWIFT_VERSION}-RELEASE/${SWIFT_PACKAGE}.tar.gz"

  echo "Downloading Swift ${SWIFT_VERSION} for Ubuntu..."

  # Download Swift
  curl -sL "$SWIFT_URL" -o /tmp/swift.tar.gz

  # Extract to /opt
  echo "Extracting Swift..."
  mkdir -p /opt/swift
  tar xzf /tmp/swift.tar.gz -C /opt/swift --strip-components=1
  rm /tmp/swift.tar.gz

  # Install required dependencies
  apt-get update > /dev/null 2>&1
  apt-get install -y binutils git gnupg2 libc6-dev libcurl4 libedit2 \
    libgcc-9-dev libpython3.8 libsqlite3-0 libstdc++-9-dev libxml2 \
    libz3-dev pkg-config tzdata zlib1g-dev > /dev/null 2>&1

  # Add Swift to PATH
  export PATH="/opt/swift/usr/bin:$PATH"

  # Persist environment variables for subsequent commands
  if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export PATH="/opt/swift/usr/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
    echo "export SWIFT_VERSION=${SWIFT_VERSION}" >> "$CLAUDE_ENV_FILE"
  fi

  # Verify installation
  echo "Swift installation complete: $(swift --version)"
else
  echo "Unsupported OS: $OS"
  exit 2
fi

exit 0
