# PR Inbox — releases

PR Inbox is a macOS menu-bar app that shows the pull requests waiting for your review, and your own open
PRs. This repository only holds its releases and installer (the source is private).

## Install

Requirements: a Mac with Apple Silicon (M1 or later).

```sh
curl -fsSL https://raw.githubusercontent.com/davidmatas/pr-inbox-releases/main/install.sh | bash
```

PR Inbox opens in the menu bar and starts at every login. It connects with your GitHub CLI login
(`brew install gh && gh auth login`), or with a personal access token pasted in its Settings.

## Update

PR Inbox checks for new versions by itself and offers them at the top of its popover — click
**Update and restart**. You can also right-click the menu-bar icon → **Check for Updates…**, or run the
install command again.

## Uninstall

1. Right-click the menu-bar icon → Quit.
2. Delete `/Applications/PR Inbox.app`.
3. Remove it from System Settings → General → Login Items if it is still listed.
4. Optionally delete `~/Library/Application Support/PR Inbox` and `~/Library/Logs/PR Inbox`, and a saved
   token: `security delete-generic-password -s pr-review-dialog -a github-pat`.

## Troubleshooting

- **"Reconnect needed":** run `gh auth refresh` (or `gh auth login`); if you saved a token in Settings, it
  takes precedence — delete it with the command above to use `gh`.
- **An update failed:** the previous version keeps running; details are in `~/Library/Logs/PR Inbox/update.log`.
