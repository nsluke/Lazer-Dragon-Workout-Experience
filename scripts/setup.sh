#!/bin/bash
# setup.sh — One-time developer environment setup.
#
# Usage: ./scripts/setup.sh
#
set -euo pipefail

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  LAZER DRAGON DEVELOPER SETUP               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Install git hooks
echo "→ Installing git hooks..."
cp scripts/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
echo "  ✅ pre-push hook installed"

# Install Fastlane (if Gemfile exists)
if [ -f Gemfile ]; then
  echo ""
  echo "→ Installing Ruby dependencies..."
  if command -v bundle &>/dev/null; then
    bundle install --quiet
    echo "  ✅ Fastlane installed"
  else
    echo "  ⚠️  bundler not found. Install with: gem install bundler"
  fi
fi

# Verify Xcode
echo ""
echo "→ Checking Xcode..."
XCODE_VERSION=$(xcodebuild -version | head -1)
echo "  ✅ $XCODE_VERSION"

# Verify simulator
echo ""
echo "→ Checking simulators..."
if xcrun simctl list devices available | grep -q "iPhone 16 Pro"; then
  echo "  ✅ iPhone 16 Pro simulator available"
else
  echo "  ⚠️  iPhone 16 Pro simulator not found. Install via Xcode > Settings > Platforms"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  SETUP COMPLETE                             ║"
echo "╠══════════════════════════════════════════════╣"
echo "║                                              ║"
echo "║  Open: CodeDump.xcodeproj (NOT .xcworkspace) ║"
echo "║  Test: Cmd+U or ./scripts/check-coverage.sh  ║"
echo "║  Gate: bundle exec fastlane gate_pr           ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
