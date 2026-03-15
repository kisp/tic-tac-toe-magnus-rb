{
  description = "tic-tac-toe-magnus-rb — Ruby + Rust gem packaging practice with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Provides the `rust-overlay` so we can pin a specific Rust toolchain.
    rust-overlay = {
      url  = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # ── Nixpkgs with the Rust overlay applied ─────────────────────────────
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        # ── Rust toolchain ────────────────────────────────────────────────────
        # We use rust-bin to get the exact version Magnus requires.
        # `rust-bin.stable.latest.default` tracks the current stable release.
        # Pin to a specific version for full reproducibility, e.g.:
        #   rust-bin.stable."1.78.0".default
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          # Extensions needed for a pleasant Rust dev experience
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };

        # ── Ruby ──────────────────────────────────────────────────────────────
        ruby = pkgs.ruby_3_3;

        # ── Native build inputs shared by devShell & package ─────────────────
        nativeDeps = [
          rustToolchain
          pkgs.pkg-config
          pkgs.libiconv           # required on macOS; harmless on Linux
        ];

        # ── Bundle environment ─────────────────────────────────────────────────
        # `bundlerEnv` resolves Gemfile.lock into a closed set of Ruby gems.
        # Run `bundle lock` locally first to generate Gemfile.lock, then let
        # `bundix` produce gemset.nix:
        #
        #   bundle lock
        #   bundix
        #
        # The gemset.nix is committed to the repo and consumed here.
        gems = pkgs.bundlerEnv {
          name        = "tic-tac-toe-magnus-rb-gems";
          inherit ruby;
          gemdir      = ./.;            # reads Gemfile + Gemfile.lock + gemset.nix
          # Pass the native build deps so rake-compiler / rb_sys can invoke
          # cargo during the bundled-gem build phase.
          nativeBuildInputs = nativeDeps;
        };

      in {
        # ── `nix develop` ─────────────────────────────────────────────────────
        devShells.default = pkgs.mkShell {
          name = "tic-tac-toe-magnus-rb";

          packages = [
            ruby
            gems                    # all Gemfile gems, including rake-compiler
            rustToolchain
            pkgs.pkg-config
            pkgs.libiconv
            pkgs.bundix             # helper: gems → gemset.nix
            pkgs.cargo-edit         # nice-to-have: cargo add/rm/upgrade
            pkgs.cargo-watch        # nice-to-have: cargo watch -x test
          ];

          # Point rb_sys at the correct Ruby so it finds ruby.h / libruby.
          shellHook = ''
            export RUBY_ROOT="${ruby}"
            export RUBY_INCLUDE_DIR="${ruby}/include"

            # Put the compiled extension on the Ruby load path so you can
            # `require "tictactoe"` directly without installing the gem.
            export RUBYLIB="$PWD/lib:$RUBYLIB"

            echo ""
            echo "  🦀💎 tic-tac-toe-magnus-rb dev shell"
            echo ""
            echo "  Ruby   : $(ruby --version)"
            echo "  Rust   : $(rustc --version)"
            echo "  Cargo  : $(cargo --version)"
            echo ""
            echo "  Quick start:"
            echo "    bundle exec rake compile   # build the Rust extension"
            echo "    bundle exec rake test      # run the test suite"
            echo "    bundle exec ruby examples/demo.rb"
            echo ""
          '';
        };

        # ── `nix build` ───────────────────────────────────────────────────────
        # Produces the compiled gem (.gem file) in result/
        packages.default = pkgs.stdenv.mkDerivation {
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

            # Compile the Rust extension via rake-compiler / rb_sys
            bundle exec rake compile
          '';

          installPhase = ''
            mkdir -p $out/lib
            # Copy the full gem source (with compiled .so) to the output
            cp -r . $out/lib/tic-tac-toe-magnus-rb
          '';

          # The Rust build fetches nothing from the network; Cargo deps must
          # be vendored.  See `nix/vendor-cargo-deps.nix` for how to do this
          # with `fetchCargoTarball` or `importCargoLock`.
          #
          # For now we note this as a TODO and rely on the devShell for
          # iterative work:
          meta = {
            description = "Tic Tac Toe engine — Rust core, Ruby API via Magnus";
            homepage    = "https://github.com/example/tic-tac-toe-magnus-rb";
            license     = pkgs.lib.licenses.mit;
            maintainers = [];
          };
        };

        # ── `nix run` ─────────────────────────────────────────────────────────
        # Runs the demo script directly.
        apps.demo = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "ttt-demo" ''
            cd ${self.packages.${system}.default}/lib/tic-tac-toe-magnus-rb
            ${ruby}/bin/ruby examples/demo.rb
          '';
        };
      }
    );
}
