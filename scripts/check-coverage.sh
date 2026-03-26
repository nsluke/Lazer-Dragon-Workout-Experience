#!/bin/bash
# check-coverage.sh — Run tests with coverage and enforce minimum threshold.
#
# Usage:
#   ./scripts/check-coverage.sh          # Run all tests, check 70% threshold
#   ./scripts/check-coverage.sh 80       # Custom threshold
#   RECORD_SNAPSHOTS=1 ./scripts/check-coverage.sh  # Record snapshot baselines
#
set -euo pipefail

THRESHOLD="${1:-70}"
SCHEME="CodeDump"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro,OS=18.0"
RESULT_BUNDLE="TestResults.xcresult"

echo "🧪 Running tests with coverage (threshold: ${THRESHOLD}%)..."
echo ""

# Clean previous results
rm -rf "$RESULT_BUNDLE"

# Build & test
xcodebuild test \
  -project CodeDump.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" \
  -skip-testing:CodeDumpUITests \
  -skip-testing:CodeDumpTests/StravaE2ETests \
  2>&1 | xcbeautify 2>/dev/null || cat

echo ""
echo "📊 Coverage Report"
echo "═══════════════════════════════════════════════"

# Extract coverage
xcrun xccov view --report --json "$RESULT_BUNDLE" > coverage.json

python3 << 'PYEOF'
import json, sys

data = json.load(open("coverage.json"))
threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 70

# Overall
overall = data.get("lineCoverage", 0) * 100
print(f"\n  Overall:  {overall:.1f}%")

# Per target
for target in data.get("targets", []):
    name = target.get("name", "?")
    cov = target.get("lineCoverage", 0) * 100
    if cov > 0:
        icon = "✅" if cov >= threshold else "⚠️"
        print(f"  {icon} {name}: {cov:.1f}%")

# Strava files detail
strava_files = []
for target in data.get("targets", []):
    for f in target.get("files", []):
        if "Strava" in f.get("path", ""):
            strava_files.append(f)

if strava_files:
    print("\n  Strava Files:")
    total = covered = 0
    for f in strava_files:
        name = f["path"].split("/")[-1]
        cov = f.get("lineCoverage", 0) * 100
        lines = f.get("executableLines", 0)
        cov_lines = f.get("coveredLines", 0)
        total += lines
        covered += cov_lines
        icon = "✅" if cov >= 80 else "⚠️" if cov >= 50 else "❌"
        print(f"    {icon} {name}: {cov:.1f}% ({cov_lines}/{lines} lines)")
    if total > 0:
        pct = covered / total * 100
        print(f"    ── Strava total: {pct:.1f}%")

print()
if overall < threshold:
    print(f"  ❌ FAIL: {overall:.1f}% < {threshold:.0f}% threshold")
    sys.exit(1)
else:
    print(f"  ✅ PASS: {overall:.1f}% >= {threshold:.0f}% threshold")
PYEOF

# Clean up
rm -f coverage.json
