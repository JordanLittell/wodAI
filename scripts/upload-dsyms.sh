#!/bin/sh
# Uploads the app's dSYMs to Sentry (adapt-0w / apple-ios) so the stack traces
# on its issues are symbolicated. Runs as the wodAI target's last build phase.
#
# Only builds that produce a dSYM upload: Release, which includes archives.
# Debug builds (and so the test runs) use plain dwarf and skip.
#
# Setup, once per machine:
#   brew install getsentry/tools/sentry-cli
#   sentry-cli login        # stores an auth token in ~/.sentryclirc
# (or export SENTRY_AUTH_TOKEN for CI).
#
# Never fails the build: a missing CLI, token or network only warns.

if [ "$DEBUG_INFORMATION_FORMAT" != "dwarf-with-dsym" ]; then
    exit 0
fi

# Xcode's build environment doesn't include Homebrew's path.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v sentry-cli >/dev/null 2>&1; then
    echo "warning: sentry-cli isn't installed, so this build's dSYMs weren't sent to Sentry (brew install getsentry/tools/sentry-cli)"
    exit 0
fi

export SENTRY_ORG=adapt-0w
export SENTRY_PROJECT=apple-ios

if ! ERROR=$(sentry-cli debug-files upload --include-sources "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null); then
    echo "warning: dSYM upload to Sentry failed: $ERROR"
fi
exit 0
