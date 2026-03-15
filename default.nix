# default.nix — classical nix-build (no flakes)
#
# Usage:
#   nix-build          # produces result/ with the compiled gem tree
#   nix-build -A shell # same as `nix-shell` (alternative entry point)
#
# Prerequisites:
#   • Gemfile.lock and gemset.nix must exist (run `bundle lock && bundix`)
#   • Cargo.lock must exist (run `cargo generate-lockfile` in ext/tictactoe/)
#   • Cargo dependencies must be vendored — see nix/vendor-cargo-deps.nix
#
# nixpkgs is provided via NIX_PATH (set by cachix/install-nix-action in CI,
# or by your local nix channel).  Override with -I nixpkgs=... if needed.

let
  pkgs = import <nixpkgs> {};

  # ── Ruby ──────────────────────────────────────────────────────────────────
  ruby = pkgs.ruby_3_3;

  # ── Native build inputs ────────────────────────────────────────────────────
  nativeDeps = [
    pkgs.rustup
    pkgs.pkg-config
    pkgs.libiconv
  ];

  # ── Bundle environment ─────────────────────────────────────────────────────
  gems = pkgs.bundlerEnv {
    name              = "tic-tac-toe-magnus-rb-gems";
    inherit ruby;
    gemdir            = ./.;
    nativeBuildInputs = nativeDeps;
  };

in {
  # ── `nix-build` ───────────────────────────────────────────────────────────
  # Builds the gem source tree (with compiled Rust extension) into the store.
  default = pkgs.stdenv.mkDerivation {
    pname   = "tic_tac_toe_magnus";
    version = "0.1.0";

    src = ./.;

    nativeBuildInputs = nativeDeps ++ [
      ruby
      gems
      pkgs.bundix
    ];

    buildPhase = ''
      export HOME=$TMPDIR
      export RUBY_ROOT="${ruby}"

      # Compile the Rust extension via rake-compiler / rb_sys.
      # Cargo dependencies must be vendored before this step —
      # see nix/vendor-cargo-deps.nix for instructions.
      bundle exec rake compile
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp -r . $out/lib/tic-tac-toe-magnus-rb
    '';

    meta = with pkgs.lib; {
      description = "Tic Tac Toe engine — Rust core, Ruby API via Magnus";
      homepage    = "https://github.com/kisp/tic-tac-toe-magnus-rb";
      license     = licenses.mit;
      maintainers = [];
    };
  };

  # ── `nix-build -A shell` (or just use nix-shell / shell.nix) ─────────────
  shell = import ./shell.nix;
}
