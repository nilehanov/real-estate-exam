#!/bin/bash
set -euo pipefail

# Sync web assets to www/ (Capacitor serves from webDir: "www")
cp index.html www/index.html
mkdir -p www/fonts
cp fonts/*.woff2 www/fonts/

echo "www/ synced from index.html"

# Run Capacitor sync to push web assets into the Xcode project
npx cap sync ios

echo "Capacitor iOS sync complete. Ready to build."
