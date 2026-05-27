# homebrew-copad

Homebrew tap for [copad](https://github.com/marshallku/copad) — a cross-platform custom terminal emulator with shared Rust core and platform-native UIs.

## Install

```bash
brew tap marshallku/copad
brew install --cask copad
```

Or in one command:

```bash
brew install --cask marshallku/copad/copad
```

## What gets installed

| Path | Source |
|---|---|
| `/Applications/Copad.app` | GUI terminal |
| `$(brew --prefix)/bin/coctl` | CLI control tool |
| `$(brew --prefix)/bin/copadd` | Background daemon (status bar, plugin runtime) |
| `~/Library/Application Support/copad/plugins/<name>/` | Plugin binaries + manifests (echo, git, llm, calendar, kb, todo, bookmark, slack, discord, jira) |
| `~/Library/LaunchAgents/com.marshall.copad.daemon.plist` | Auto-starts `copadd` at login |
| `~/.config/copad/shell-hooks/copad-cwd.{bash,zsh,fish}` | Live-cwd reporting hooks (source one from your rc file) |

After install, source the shell hook for your shell so session restore lands at your current dir:

```bash
# zsh
echo 'source ~/.config/copad/shell-hooks/copad-cwd.zsh' >> ~/.zshrc

# bash
echo 'source ~/.config/copad/shell-hooks/copad-cwd.bash' >> ~/.bashrc

# fish
echo 'source ~/.config/copad/shell-hooks/copad-cwd.fish' >> ~/.config/fish/config.fish
```

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (arm64). Intel Mac users build from source via [`scripts/install-macos.sh`](https://github.com/marshallku/copad/blob/master/scripts/install-macos.sh)

## Uninstall

```bash
brew uninstall --cask copad             # leaves user state intact
brew uninstall --cask --zap copad       # also nukes ~/Library/Application Support/copad, ~/.config/copad, logs, saved state
```

## License

MIT. See the [copad repo](https://github.com/marshallku/copad/blob/master/LICENSE).
