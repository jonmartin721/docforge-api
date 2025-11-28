#!/bin/bash

# setup-linux.sh
# Installs dependencies for DocForge API (Puppeteer/Chrome) on Linux/WSL

set -e

echo "🔧 DocForge Linux Setup"
echo "======================="

# Check for sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./scripts/setup-linux.sh)"
  exit 1
fi

echo "📦 Updating package lists..."
apt-get update

echo "📦 Installing base dependencies..."
# Common dependencies for Puppeteer
DEPS="ca-certificates fonts-liberation libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 lsb-release wget xdg-utils"

# Handle libasound2 vs libasound2t64 (Ubuntu 24.04+)
if apt-cache show libasound2t64 >/dev/null 2>&1; then
    echo "   Detected newer Ubuntu (using libasound2t64)"
    DEPS="$DEPS libasound2t64"
else
    echo "   Using standard libasound2"
    DEPS="$DEPS libasound2"
fi

apt-get install -y $DEPS

echo "✅ Dependencies installed."

# Fix permissions if the app has been built/run
echo "🔧 Checking Chrome permissions..."
FOUND_CHROME=false

for config in Debug Release; do
    CHROME_PATH="./DocumentGenerator.API/bin/$config/net8.0/Chrome"
    if [ -d "$CHROME_PATH" ]; then
        echo "   Fixing permissions for $config build..."
        find "$CHROME_PATH" -name "chrome" -exec chmod +x {} \;
        find "$CHROME_PATH" -name "chrome_crashpad_handler" -exec chmod +x {} \;
        FOUND_CHROME=true
    fi
done

if [ "$FOUND_CHROME" = true ]; then
    echo "✅ Permissions fixed."
else
    echo "ℹ️  Chrome binary not found yet (will be downloaded on first run)."
    echo "   If you get 'Permission denied' errors later, run this script again."
fi

echo "======================="
echo "🎉 Setup complete! You can now run the API."
