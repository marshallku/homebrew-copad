cask "copad" do
  version "0.2.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/marshallku/copad/releases/download/v#{version}/copad-v#{version}-aarch64-apple-darwin.tar.gz"
  name "copad"
  desc "Cross-platform custom terminal emulator with shared Rust core"
  homepage "https://github.com/marshallku/copad"

  # Info.plist sets LSMinimumSystemVersion 14.0. arm64-only artifact today;
  # Intel users build from source via scripts/install-macos.sh.
  depends_on macos: :sonoma
  depends_on arch: :arm64

  # Tarball layout produced by .github/workflows/release.yml (build-macos):
  #   Copad.app/
  #   coctl
  #   copadd
  #   plugins/<name>/{copad-plugin-<name>, plugin.toml, panel.html?, triggers.example.toml?}
  #   shell-hooks/copad-cwd.{bash,zsh,fish}
  #   com.marshall.copad.daemon.plist   (HOME_PLACEHOLDER unsubstituted)
  app "Copad.app"
  binary "coctl"
  binary "copadd"

  postflight do
    require "fileutils"

    # PluginSupervisor (copad-daemon) discovers plugins at startup from
    # ~/Library/Application Support/copad/plugins/<name>/. Mirror that
    # layout from the staged tarball.
    plugins_dst = File.expand_path("~/Library/Application Support/copad/plugins")
    FileUtils.mkdir_p(plugins_dst)
    Dir.glob("#{staged_path}/plugins/*").each do |src|
      next unless File.directory?(src)

      dst = File.join(plugins_dst, File.basename(src))
      FileUtils.rm_r(dst)
      FileUtils.cp_r(src, dst)
    end

    # Shell hooks for live-cwd reporting (sourced from user's rc file).
    hooks_dst = File.expand_path("~/.config/copad/shell-hooks")
    FileUtils.mkdir_p(hooks_dst)
    Dir.glob("#{staged_path}/shell-hooks/copad-cwd.*").each do |src|
      FileUtils.cp(src, File.join(hooks_dst, File.basename(src)))
    end

    # LaunchAgent. The brew `binary` stanza above symlinks copadd into
    # HOMEBREW_PREFIX/bin, so the plist points there directly — no
    # HOME_PLACEHOLDER substitution needed (launchd does not expand `~`,
    # which is why the in-repo plist ships with a placeholder for the dev
    # install path). Write the plist fresh each install so a HOMEBREW_PREFIX
    # change (Intel → arm64 reinstall, custom prefix) is reflected.
    plist_dst = File.expand_path("~/Library/LaunchAgents/com.marshall.copad.daemon.plist")
    plist_body = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.marshall.copad.daemon</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{HOMEBREW_PREFIX}/bin/copadd</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>#{Dir.home}/Library/Logs/copad-daemon.out.log</string>
        <key>StandardErrorPath</key>
        <string>#{Dir.home}/Library/Logs/copad-daemon.err.log</string>
        <key>EnvironmentVariables</key>
        <dict>
          <key>RUST_LOG</key>
          <string>info</string>
        </dict>
        <key>ProcessType</key>
        <string>Interactive</string>
      </dict>
      </plist>
    PLIST
    FileUtils.mkdir_p(File.dirname(plist_dst))
    File.write(plist_dst, plist_body)
  end

  # `launchctl:` boots the daemon out, which also tears down its running
  # instance — no separate `signal:` needed for copadd. `quit:` sends an
  # Apple Event to the GUI app via its bundle id. `delete:` removes the
  # plist we wrote in postflight, since brew only tracks artifacts declared
  # in the cask DSL itself.
  uninstall launchctl: "com.marshall.copad.daemon",
            quit:      "com.marshall.copad",
            delete:    "~/Library/LaunchAgents/com.marshall.copad.daemon.plist"

  # `zap` runs only on `brew uninstall --zap copad` — destroys user state.
  zap trash: [
    "~/.config/copad",
    "~/Library/Application Support/copad",
    "~/Library/Caches/copad",
    "~/Library/Logs/copad-daemon.err.log",
    "~/Library/Logs/copad-daemon.out.log",
    "~/Library/Saved Application State/com.marshall.copad.savedState",
  ]
end
