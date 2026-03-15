# Bundix workflow

`bundix` converts a `Gemfile.lock` into a `gemset.nix` that Nix can use to
build a closed, reproducible set of Ruby gems without touching the internet at
build time.

## First-time setup

```sh
# 1. Enter the dev shell (this already has bundix on PATH)
nix-shell

# 2. Install gems and produce Gemfile.lock
bundle install

# 3. Convert Gemfile.lock → gemset.nix
bundix

# 4. Commit both files — they are the Nix lockfile for Ruby deps
git add Gemfile.lock gemset.nix
```

## Updating a gem

```sh
nix-shell
bundle update <gem_name>   # updates Gemfile.lock
bundix                     # regenerates gemset.nix
git add Gemfile.lock gemset.nix
```

## How it fits together

```
Gemfile          ← human-written dependency spec
    │
    │  bundle install
    ▼
Gemfile.lock     ← exact versions resolved by Bundler
    │
    │  bundix
    ▼
gemset.nix       ← SHA-256 hashes for every gem; consumed by bundlerEnv
    │
    │  nix-shell / nix-build
    ▼
/nix/store/...   ← immutable, content-addressed gem closures
```

## Native extensions (rb_sys / rake-compiler)

`bundlerEnv` passes `nativeBuildInputs` down to each gem that has a
`Makefile`-style extension.  Because `rustup` is in that list,
`rb_sys` can invoke `cargo build --release` during the gem install phase
inside the Nix sandbox.

The extension sandbox has **no network access**, so the Cargo dependency
graph must be vendored (see `nix/vendor-cargo-deps.nix`).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `bundlerEnv` complains about missing `gemset.nix` | Run `bundix` and commit the result |
| Cargo can't find crates | Vendor deps via Approach A/B/C in `vendor-cargo-deps.nix` |
| Wrong Ruby version in shell | Change `ruby = pkgs.ruby_3_3` in `shell.nix` |
| `libruby` not found during ext compile | Ensure `RUBY_ROOT` is set (the `shellHook` does this) |
