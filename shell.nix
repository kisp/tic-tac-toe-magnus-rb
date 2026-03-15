# shell.nix — classical nix-shell (no flakes)
#
# Usage:
#   nix-shell                              # enter the dev shell
#   nix-shell --run 'bundle exec rake test'
#
# With direnv + nix-direnv:
#   echo "use nix" > .envrc && direnv allow
#
# Update the nixpkgs pin:
#   nix-prefetch-url --unpack \
#     https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz

let
  # ── Pin nixpkgs for reproducibility ───────────────────────────────────────
  # Replace <rev> and sha256 after running the nix-prefetch-url command above.
  pkgs = import (fetchTarball {
    url    = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    # sha256 = "0000000000000000000000000000000000000000000000000000"; # update me
  }) {};

  # ── Ruby ──────────────────────────────────────────────────────────────────
  ruby = pkgs.ruby_3_3;

  # ── Native build inputs shared by bundlerEnv & mkShell ────────────────────
  nativeDeps = [
    pkgs.rustup          # manages stable / nightly Rust toolchains
    pkgs.pkg-config
    pkgs.libiconv        # required on macOS; harmless on Linux
    pkgs.clang           # provides libclang for rb-sys / bindgen
  ];

  # ── Bundle environment (optional — requires gemset.nix) ───────────────────
  # `bundlerEnv` resolves Gemfile.lock into a closed set of Ruby gems.
  # Run `bundle lock` then `bundix` to regenerate gemset.nix:
  #
  #   bundle lock
  #   bundix
  #
  # Commit both Gemfile.lock and gemset.nix — they are the Nix lockfiles.
  # When gemset.nix is absent (e.g. fresh clone), gems are managed by
  # `bundle install` instead and bundlerEnv is omitted from the shell.
  gems = if builtins.pathExists ./gemset.nix
         then pkgs.bundlerEnv {
           name              = "tic-tac-toe-magnus-rb-gems";
           inherit ruby;
           gemdir            = ./.;      # reads Gemfile + Gemfile.lock + gemset.nix
           nativeBuildInputs = nativeDeps;
         }
         else null;

in pkgs.mkShell {
  name = "tic-tac-toe-magnus-rb";

  buildInputs = [
    ruby
  ] ++ (if gems != null then [ gems ] else [])  # Gemfile gems on PATH when available
    ++ nativeDeps ++ [
    pkgs.bundix         # gems → gemset.nix helper
    pkgs.cargo-edit     # cargo add / rm / upgrade
    pkgs.cargo-watch    # cargo watch -x test
  ];

  # rb-sys / bindgen need to locate libclang from the Nix store, not the system.
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

  shellHook = ''
    # Install the stable Rust toolchain (downloaded once, cached by rustup).
    rustup toolchain install stable \
      --component rust-src rust-analyzer clippy rustfmt 2>/dev/null || true
    rustup default stable

    # Point rb_sys at the correct Ruby so it finds ruby.h / libruby.
    export RUBY_ROOT="${ruby}"
    export RUBY_INCLUDE_DIR="${ruby}/include"

    # Put the compiled extension on the load path so you can
    # `require "tictactoe"` directly without installing the gem.
    export RUBYLIB="$PWD/lib:$RUBYLIB"

    echo ""
    echo "  🦀💎 tic-tac-toe-magnus-rb dev shell"
    echo ""
    echo "  Ruby   : $(ruby --version)"
    echo "  Rust   : $(rustc --version 2>/dev/null || echo '(run: rustup toolchain install stable)')"
    echo "  Cargo  : $(cargo --version 2>/dev/null || echo '(run: rustup toolchain install stable)')"
    echo ""
    echo "  Quick start:"
    echo "    bundle exec rake compile   # build the Rust extension"
    echo "    bundle exec rake test      # run the test suite"
    echo "    bundle exec ruby examples/demo.rb"
    echo ""
  '';
}
