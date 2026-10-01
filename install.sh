#!/usr/bin/env bash
# Install or update PR Inbox from the public releases repo (distribution phases 1-2, spec §2).
#   curl -fsSL https://raw.githubusercontent.com/davidmatas/pr-inbox-releases/main/install.sh | bash
# Pin a version (prereleases included): PR_INBOX_VERSION=v0.3.0 before `bash`.
# The zip arrives through curl, which sets no quarantine attribute, so Gatekeeper never prompts even
# though the app is only ad-hoc signed. After this, PR Inbox updates itself from the menu bar.
set -euo pipefail

repo="davidmatas/pr-inbox-releases"
app_name="PR Inbox"
target="/Applications/${app_name}.app"

fail() { echo "✗ $1" >&2; exit 1; }

[ "$(uname -m)" = "arm64" ] || fail "PR Inbox needs a Mac with Apple Silicon."
[ -w /Applications ] || fail "Cannot write to /Applications — use an admin account."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

tag="${PR_INBOX_VERSION:-}"
if [ -z "$tag" ]; then
  code="$(curl -sS -o "${work}/latest.json" -w '%{http_code}' -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null)" || code="000"
  case "$code" in
    200) tag="$(plutil -extract tag_name raw - < "${work}/latest.json" 2>/dev/null)" || fail "Could not find the latest PR Inbox release." ;;
    404) fail "No stable PR Inbox release is published yet — pin one with PR_INBOX_VERSION=vX.Y.Z." ;;
    *) fail "Could not reach GitHub to find the latest PR Inbox release (HTTP ${code})." ;;
  esac
fi
case "$tag" in v*) ;; *) tag="v${tag}" ;; esac
version="${tag#v}"
url="https://github.com/${repo}/releases/download/${tag}/PR-Inbox-${version}-arm64.zip"

echo "→ Downloading PR Inbox ${version}…"
curl -fL --progress-bar -o "${work}/pr-inbox.zip" "$url" || fail "Could not download ${url}."

if pgrep -x "$app_name" >/dev/null 2>&1; then
  echo "→ Quitting the running PR Inbox…"
  osascript -e "quit app \"${app_name}\"" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do pgrep -x "$app_name" >/dev/null 2>&1 || break; sleep 0.5; done
  pkill -x "$app_name" 2>/dev/null || true
fi

echo "→ Installing to ${target}…"
ditto -x -k "${work}/pr-inbox.zip" "${work}/unzipped"
rm -rf "$target"
ditto "${work}/unzipped/${app_name}.app" "$target"
xattr -dr com.apple.quarantine "$target" 2>/dev/null || true

open -a "$target"
installed="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${target}/Contents/Info.plist")"
echo "✓ PR Inbox ${installed} is running — look for the check mark in the menu bar."

if ! command -v gh >/dev/null 2>&1 || ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "ℹ PR Inbox connects through the GitHub CLI (gh auth login), or paste a token in its Settings."
fi
