#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/../native/LauncherApp.m"

fail() {
  print -u2 "Lifecycle check failed: $1"
  exit 1
}

source_contains() {
  local pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    rg -q -- "$pattern" "$SOURCE"
  else
    grep -Eq -- "$pattern" "$SOURCE"
  fi
}

dismiss_body="$(sed -n '/- (void)dismissLauncher/,/^}/p' "$SOURCE")"
close_body="$(sed -n '/- (void)windowWillClose/,/^}/p' "$SOURCE")"

[[ "$dismiss_body" != *'[NSApp terminate:nil]'* ]] || fail "dismissing the launcher must not terminate the process"
[[ "$dismiss_body" == *'[strongSelf.window orderOut:nil]'* ]] || fail "dismissing must hide the window"
[[ "$dismiss_body" == *'[NSApp hide:nil]'* ]] || fail "dismissing must hide the application"
[[ "$close_body" != *'[NSApp terminate:nil]'* ]] || fail "closing the window must not terminate the process"
source_contains '- \(BOOL\)applicationShouldHandleReopen:' || fail "Dock reopen handler is missing"
source_contains '- \(void\)showLauncher' || fail "window restore method is missing"

echo "Lifecycle check passed"
