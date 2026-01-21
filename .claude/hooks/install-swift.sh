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
  # Use Swift 6.2.3 for Ubuntu 22.04 (matching .swift-version)
  SWIFT_VERSION="6.2.3"
  SWIFT_PLATFORM="ubuntu22.04"
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

  # Install required dependencies for Swift 6.2 on Ubuntu 22.04
  apt-get update > /dev/null 2>&1
  apt-get install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 \
    libgcc-11-dev libpython3-dev libsqlite3-0 libstdc++-11-dev libxml2-dev \
    libz3-dev pkg-config tzdata zlib1g-dev unzip > /dev/null 2>&1

  # Add Swift to PATH
  export PATH="/opt/swift/usr/bin:$PATH"

  # Persist environment variables for subsequent commands
  if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export PATH="/opt/swift/usr/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
    echo "export SWIFT_VERSION=${SWIFT_VERSION}" >> "$CLAUDE_ENV_FILE"
  fi

  # Verify installation
  echo "Swift installation complete: $(swift --version)"

  # Install swiftformat
  echo "Installing swiftformat..."
  if ! command -v swiftformat &> /dev/null; then
    git clone --depth 1 --branch 0.54.6 https://github.com/nicklockwood/SwiftFormat.git /tmp/SwiftFormat
    cd /tmp/SwiftFormat
    swift build -c release
    cp .build/release/swiftformat /usr/local/bin/
    cd -
    rm -rf /tmp/SwiftFormat
    echo "swiftformat installed: $(swiftformat --version)"
  else
    echo "swiftformat already installed: $(swiftformat --version)"
  fi

  # Install swiftlint
  echo "Installing swiftlint..."
  if ! command -v swiftlint &> /dev/null; then
    SWIFTLINT_VERSION="0.57.1"
    curl -sL "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/swiftlint_linux.zip" -o /tmp/swiftlint.zip
    unzip -q /tmp/swiftlint.zip -d /tmp/swiftlint
    mv /tmp/swiftlint/swiftlint /usr/local/bin/
    chmod +x /usr/local/bin/swiftlint
    rm -rf /tmp/swiftlint.zip /tmp/swiftlint
    echo "swiftlint installed: $(swiftlint version)"
  else
    echo "swiftlint already installed: $(swiftlint version)"
  fi
else
  echo "Unsupported OS: $OS"
  exit 2
fi

exit 0
