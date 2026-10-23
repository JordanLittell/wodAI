#!/usr/bin/env bash
# Runs the unit tests and the week-navigation UI test on an iOS Simulator.
# CI (.github/workflows/ios-tests.yml) runs exactly this.
#
#   scripts/run-tests.sh                    # newest available iPhone simulator
#   SIMULATOR="iPhone 17" scripts/run-tests.sh
#
# Results land in build/TestResults.xcresult.
#
# Skipped: Xcode's template UI tests, and ZZRenderStatCards, which renders
# Activity cards to a PNG for eyeballing rather than testing anything.
# One simulator, not parallel clones: a clone sometimes fails to launch the
# UI test runner. Signing: ad hoc (`-`), so no team or certificate is needed; the Simulator
# won't launch an unsigned UI test runner.
set -euo pipefail

cd "$(dirname "$0")/.."

# The newest iPhone simulator on the newest installed iOS runtime, unless named.
if [[ -z "${SIMULATOR:-}" ]]; then
  SIMULATOR=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["devices"]
ios = sorted((r for r in runtimes if "iOS" in r), key=lambda r: [int(p) for p in r.rsplit("iOS-", 1)[1].split("-")])
for runtime in reversed(ios):
    phones = [d["name"] for d in runtimes[runtime] if d["name"].startswith("iPhone")]
    if phones:
        print(phones[-1])
        break
')
fi
if [[ -z "$SIMULATOR" ]]; then
  echo "No iPhone simulator available" >&2
  exit 1
fi
echo "Testing on: $SIMULATOR"

RESULTS=build/TestResults.xcresult
rm -rf "$RESULTS"

xcodebuild test \
  -project wodAI.xcodeproj \
  -scheme wodAI \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$SIMULATOR,OS=latest" \
  -only-testing:wodAITests \
  -only-testing:wodAIUITests/WeekNavigationUITests \
  -skip-testing:wodAITests/ZZRenderStatCards \
  -parallel-testing-enabled NO \
  -resultBundlePath "$RESULTS" \
  CODE_SIGN_IDENTITY=-
