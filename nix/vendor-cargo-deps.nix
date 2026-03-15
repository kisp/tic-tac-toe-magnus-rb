# nix/vendor-cargo-deps.nix
#
# Helper that vendors the Cargo dependency graph so `nix-build` never hits
# the network.  Two approaches are shown — pick one.
#
# ─────────────────────────────────────────────────────────────────────────────
# APPROACH A — importCargoLock (recommended, no extra tooling needed)
# ─────────────────────────────────────────────────────────────────────────────
#
#   In default.nix, inside the mkDerivation for the package:
#
#   cargoDeps = pkgs.rustPlatform.importCargoLock {
#     lockFile = ../ext/tictactoe/Cargo.lock;
#     # If any git deps appear in Cargo.lock, add their hashes here:
#     # outputHashes = {
#     #   "magnus-0.7.0" = "sha256-...";
#     # };
#   };
#
#   Then add to nativeBuildInputs:
#     pkgs.rustPlatform.cargoSetupHook
#
#   And generate Cargo.lock (not in .gitignore!) with:
#     cargo generate-lockfile --manifest-path ext/tictactoe/Cargo.toml
#
# ─────────────────────────────────────────────────────────────────────────────
# APPROACH B — fetchCargoTarball (older, explicit hash)
# ─────────────────────────────────────────────────────────────────────────────
#
#   cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
#     src         = ../ext/tictactoe;
#     name        = "tictactoe-vendor";
#     hash        = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
#     # Regenerate the hash after any Cargo.toml change:
#     #   nix-prefetch '{ pkgs ? import <nixpkgs> {} }:
#     #     pkgs.rustPlatform.fetchCargoTarball { src = ./ext/tictactoe; name = "x"; hash = ""; }'
#   };
#
# ─────────────────────────────────────────────────────────────────────────────
# APPROACH C — vendored directory committed to the repo
# ─────────────────────────────────────────────────────────────────────────────
#
#   1. Run locally:
#        cd ext/tictactoe && cargo vendor vendor/
#
#   2. Add to ext/tictactoe/.cargo/config.toml:
#        [source.crates-io]
#        replace-with = "vendored-sources"
#
#        [source.vendored-sources]
#        directory = "vendor"
#
#   3. Commit the vendor/ directory.
#      nix-build will now work fully offline — no fetchCargoTarball needed.
#
# ─────────────────────────────────────────────────────────────────────────────
# Which approach to use?
#
#   • Small team, no strict hermetic requirement → Approach A (easiest)
#   • CI/CD with no outbound network             → Approach C (most reliable)
#   • Exact hash pinning required                → Approach B
# ─────────────────────────────────────────────────────────────────────────────

# This file is documentation only — nothing to evaluate.
{}
