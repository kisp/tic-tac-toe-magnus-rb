# shell.nix — for users who haven't switched to Nix flakes yet.
#
# Usage:
#   nix-shell          # enter the dev shell
#   nix-shell --run 'bundle exec rake test'
#
# If you are using flakes, prefer `nix develop` instead.

let
  # Pin nixpkgs for reproducibility.
  # Update this hash with:  nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz
  pkgs = import (fetchTarball {
    url    = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    # sha256 = "0000000000000000000000000000000000000000000000000000"; # update me
  }) {};

  ruby = pkgs.ruby_3_3;

in pkgs.mkShell {
  name = "tic-tac-toe-magnus-rb";

  buildInputs = [
    ruby
    pkgs.rustup          # manages stable / nightly toolchains
    pkgs.pkg-config
    pkgs.libiconv        # macOS compat; harmless on Linux
    pkgs.bundix          # gems → gemset.nix
    pkgs.cargo-edit
  ];

  shellHook = ''
    # Ensure rustup has the stable toolchain available
    rustup toolchain install stable --component rust-src rust-analyzer clippy rustfmt 2>/dev/null || true
    rustup default stable

    export RUBY_ROOT="${ruby}"
    export RUBY_INCLUDE_DIR="${ruby}/include"
    export RUBYLIB="$PWD/lib:$RUBYLIB"

    echo ""
    echo "  🦀💎 tic-tac-toe-magnus-rb (legacy nix-shell)"
    echo "  Ruby $(ruby --version | cut -d' ' -f2)  |  $(rustc --version)"
    echo ""
    echo "  bundle exec rake compile && bundle exec rake test"
    echo ""
  '';
}
