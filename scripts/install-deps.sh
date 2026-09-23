#!/usr/bin/env bash
#
# install-deps.sh — installs gawk, the only runtime dependency of inqr.
#
# Detects the system package manager and installs gawk if it isn't already
# present. Safe to re-run; it's a no-op if gawk is already installed.
#
set -euo pipefail

if command -v gawk >/dev/null 2>&1; then
  echo "gawk is already installed: $(gawk --version | head -1)"
  exit 0
fi

echo "gawk not found — attempting to install it..."

install_with() {
  echo "+ $*"
  "$@"
}

if command -v apt-get >/dev/null 2>&1; then
  install_with sudo apt-get update -y
  install_with sudo apt-get install -y gawk
elif command -v dnf >/dev/null 2>&1; then
  install_with sudo dnf install -y gawk
elif command -v yum >/dev/null 2>&1; then
  install_with sudo yum install -y gawk
elif command -v pacman >/dev/null 2>&1; then
  install_with sudo pacman -Sy --noconfirm gawk
elif command -v apk >/dev/null 2>&1; then
  install_with sudo apk add --no-cache gawk
elif command -v zypper >/dev/null 2>&1; then
  install_with sudo zypper install -y gawk
elif command -v brew >/dev/null 2>&1; then
  install_with brew install gawk
else
  echo "error: no supported package manager found (apt, dnf, yum, pacman, apk, zypper, brew)." >&2
  echo "Install gawk manually for your platform, then re-run inqr." >&2
  exit 1
fi

echo "Done: $(gawk --version | head -1)"
