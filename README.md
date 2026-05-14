# binary-foundry

`binary-foundry` builds and packages prebuilt binary assets from source projects.

The output is a set of tarballs that can be unpacked directly into `/` on a target Fedora-based system, plus checksum files and a release manifest.

## Goals

- Build expensive source-based tools ahead of time.
- Produce tarballs that can be extracted directly into `/`.
- Keep the build environment pinned to Fedora userspace instead of the host.
- Publish release-ready assets that other repositories can consume.

## Layout

- `config.nuon`: shared defaults such as Fedora version, base image, target architecture, shared directory locations, and the anyzig download URL.
- `manifests/*.nuon`: per-asset source/build/output definitions.
- `lib/common.nu`: shared helpers for config loading, cloning, staging, packaging, and checksums.
- `lib/toolchains.nu`: reusable Rust, Zig, and Autotools build helpers for asset scripts.
- `scripts/run-build.nu`: host-side driver that starts a Fedora container and runs one asset build or every configured asset.
- `scripts/generate-manifest.nu`: writes a release-ready `manifest.json` for built artifacts.
- `builders/*.nu`: container-side per-asset build scripts.
- `dist/`: generated tarballs, `.sha256` files, and release manifest output.
- `work/`: scratch directories used during local builds.

## Supported Assets

- `awww`
- `aria2`
- `nvim`
- `rmpc`
- `tree-sitter`

## Usage

Build one asset:

```bash
nu scripts/run-build.nu nvim
nu scripts/run-build.nu awww
```

Build all configured assets:

```bash
nu scripts/run-build.nu --all
```

Generate a release manifest after building:

```bash
nu scripts/generate-manifest.nu
```

Override the Fedora base image for a future upgrade test:

```bash
nu scripts/run-build.nu nvim --base-image registry.fedoraproject.org/fedora:45 --fedora-version 45
```

## Output format

Each build produces:

- `dist/<name>-<arch>-fedora<version>.tar.gz`
- `dist/<name>-<arch>-fedora<version>.tar.gz.sha256`
- `dist/manifest.json` after running `generate-manifest.nu`

The tarball contents are staged as a mini root filesystem such as:

```text
usr/bin/...
usr/share/...
```

The intended release flow is:

1. Build assets into `dist/`
2. Generate `dist/manifest.json`
3. Upload the tarballs, checksum files, and manifest to GitHub Releases

Consumer repositories can then download the release assets and install them during image or package builds.

## Notes

- `scripts/run-build.nu` expects `podman` on the host.
- The container image does not need Nushell preinstalled; the runner bootstraps `nu` inside Fedora before invoking the inner script.
- `scripts/run-build.nu --all` discovers assets by scanning `manifests/*.nuon`.
- Individual asset scripts should stay thin and reuse `lib/*.nu`.
- Zig-based assets use `anyzig` from the configured release URL instead of relying on Fedora's Zig package.
- `dist/` and `work/` are build outputs and are ignored by git except for `.gitkeep`.
