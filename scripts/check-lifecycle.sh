#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/../native/LauncherApp.m"

fail() {
  print -u2 "Lifecycle check failed: $1"
  exit 1
}

dismiss_body="$(sed -n '/- (void)dismissLauncher/,/^}/p' "$SOURCE")"
close_body="$(sed -n '/- (void)windowWillClose/,/^}/p' "$SOURCE")"

[[ "$dismiss_body" != *'[NSApp terminate:nil]'* ]] || fail "dismissing the launcher must not terminate the process"
[[ "$dismiss_body" == *'[strongSelf.window orderOut:nil]'* ]] || fail "dismissing must hide the window"
[[ "$dismiss_body" == *'[NSApp hide:nil]'* ]] || fail "dismissing must hide the application"
[[ "$close_body" != *'[NSApp terminate:nil]'* ]] || fail "closing the window must not terminate the process"
rg -q -- '- \(BOOL\)applicationShouldHandleReopen:' "$SOURCE" || fail "Dock reopen handler is missing"
rg -q -- '- \(void\)showLauncher' "$SOURCE" || fail "window restore method is missing"

echo "Lifecycle check passed"
