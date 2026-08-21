#!/usr/bin/env bash

# Immediately exit on errors
set -e

VERSION="v2.30.0"
REPOSITORY_ORG="filebrowser"
REPOSITORY_NAME="$REPOSITORY_ORG"
PROJECT_NAME="$REPOSITORY_ORG"
REPOSITORY_URL="https://github.com/$REPOSITORY_ORG/$REPOSITORY_NAME"

echo "Installing project $PROJECT_NAME version $VERSION"

# Step 1: Prepare the download URL

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64 | amd64)
    BUILD_NAME="linux-amd64"
    ;;
  armv7l | armhf)
    BUILD_NAME="linux-armv7"
    ;;
  aarch64 | arm64)
    BUILD_NAME="linux-arm64"
    ;;
  *)
    echo "Architecture: $ARCH is unsupported, please create a new issue on https://github.com/bluerobotics/BlueOS/issues"
    exit 1
    ;;
esac
ARTIFACT_NAME="$BUILD_NAME-$PROJECT_NAME.tar.gz"
echo "For architecture $ARCH, using build $BUILD_NAME"

REMOTE_URL="$REPOSITORY_URL/releases/download/$VERSION/$ARTIFACT_NAME"
echo "Remote URL is $REMOTE_URL"

# Step 2: Prepare the installation path

if [ -n "$VIRTUAL_ENV" ]; then
    BIN_DIR="$VIRTUAL_ENV/bin"
else
    BIN_DIR="/usr/bin"
fi
mkdir -p "$BIN_DIR"

BINARY_PATH="$BIN_DIR/$PROJECT_NAME"
echo "Installing to $BINARY_PATH"

# Step 3: Download and install

TMP_DIR=".tmp/$PROJECT_NAME"
mkdir -p "$TMP_DIR"
wget -q "$REMOTE_URL" -O - | tar -zxf - -C "$TMP_DIR"
mv "$TMP_DIR/$PROJECT_NAME" "$BINARY_PATH"
rm -rf "$TMP_DIR"
chmod +x "$BINARY_PATH"

echo "Installed binary type: $(file "$(which "$BINARY_PATH")")"

# Create configuration file
DATABASE_PATH="/etc/filebrowser/filebrowser.db"
mkdir -p "$(dirname $DATABASE_PATH)"
filebrowser config init --address=0.0.0.0 --port=7777 --auth.method=noauth --log=stdout --root=/shortcuts --database="$DATABASE_PATH"
filebrowser users add pi raspberry --database="$DATABASE_PATH"

# A second instance, rooted at SonarView's recordings folder.
#
# This needs its own database because filebrowser's root and its access rules
# are properties of the instance and its user, not of a URL. Re-rooting or
# filtering the instance above would re-root and filter the main File Browser
# page along with it, so the only way to give the SonarView Logs page its own
# home directory is to run a second one.
# Root at the real path, never at anything under /shortcuts. This script runs
# well before the Dockerfile creates the /shortcuts symlinks, and `config init`
# creates its root if missing - so rooting under /shortcuts would materialise
# /shortcuts/userdata as a real directory here, and the later
# `ln -s /usr/blueos/userdata /shortcuts/userdata` would then land *inside* it
# rather than becoming it, breaking the main File Browser's userdata shortcut.
#
# /usr/blueos/userdata is bind-mounted at runtime, so the directory created here
# is masked by the mount and the live recordings folder is what gets served.
SONARVIEW_DATABASE_PATH="/etc/filebrowser/sonarview.db"
mkdir -p /usr/blueos/userdata/SonarView
filebrowser config init --address=0.0.0.0 --port=7778 --auth.method=noauth --log=stdout --root=/usr/blueos/userdata/SonarView --database="$SONARVIEW_DATABASE_PATH"
filebrowser users add pi raspberry --database="$SONARVIEW_DATABASE_PATH"

# Hide the config and error-log files that sit alongside the recordings, so the
# page shows only the per-session folders and the .svlz files inside them. This
# is a deny rule (no --allow) scoped to this database, so the main File Browser
# still shows everything.
filebrowser rules add --regex '\.jsonl?$' --database="$SONARVIEW_DATABASE_PATH"

echo "Finished installing $PROJECT_NAME"
