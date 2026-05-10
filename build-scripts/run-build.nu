#!/usr/bin/env nu

use ../lib/common.nu *

def main [
  asset?: string,
  --all,
  --base-image: string,
  --fedora-version: string,
  --target-arch: string,
  --release-tag: string
] {
  let config = (load_config)
  let base_image = ($base_image | default $config.base_image)
  let fedora_version = ($fedora_version | default $config.fedora_version)
  let target_arch = ($target_arch | default $config.target_arch)
  let release_tag = ($release_tag | default $config.release_tag)
  let repo_root = (packaging_root)
  let dist_dir = ([$repo_root ($config.dist_dir)] | path join)
  let work_root = ([$repo_root ($config.work_root)] | path join)
  let container_dist_dir = (["/workspace" ($config.dist_dir)] | path join)
  let container_work_root = (["/workspace" ($config.work_root)] | path join)

  ensure_dir $dist_dir
  ensure_dir $work_root

  if ($all and ($asset | is-not-empty)) {
    fail "use either an asset name or --all, not both"
  }

  let assets = (
    if $all {
      list_assets
    } else if ($asset | is-not-empty) {
      [$asset]
    } else {
      fail "missing asset name; pass an asset like 'nvim' or use --all"
    }
  )

  for asset_name in $assets {
    let asset_info = (asset_config $asset_name)
    let work_dir = ([$work_root $asset_name] | path join)
    let container_work_dir = ([$container_work_root $asset_name] | path join)
    ensure_dir $work_dir

    print $"packaging: asset=($asset_name)"
    print $"packaging: base-image=($base_image)"
    print $"packaging: fedora-version=($fedora_version)"
    print $"packaging: target-arch=($target_arch)"
    print $"packaging: release-tag=($release_tag)"

    let inner_cmd = $"dnf install -y nu && nu /workspace/($asset_info.script) --dist-dir '($container_dist_dir)' --work-dir '($container_work_dir)' --fedora-version '($fedora_version)' --target-arch '($target_arch)' --release-tag '($release_tag)'"

    ^podman run --rm --arch $target_arch -v $"($repo_root):/workspace:Z" -w /workspace $base_image /bin/sh -lc $inner_cmd
  }
}
