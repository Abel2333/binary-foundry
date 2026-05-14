#!/usr/bin/env nu

use ../lib/common.nu *
use ../lib/toolchains.nu *

def main [
  --dist-dir: string,
  --work-dir: string,
  --fedora-version: string,
  --target-arch: string,
  --release-tag: string
] {
  let manifest = (asset_config "nvim")
  install_zig_deps

  let repo_dir = ([$work_dir "neovim"] | path join)
  let stage_dir = ([$work_dir "stage"] | path join)
  let install_prefix = ([$work_dir "nvim-install"] | path join)
  let artifact_name = (render_artifact_name $manifest.output.artifact $fedora_version $target_arch)
  let dist_file = ([$dist_dir $artifact_name] | path join)

  reset_dir $stage_dir
  ^rm -rf $install_prefix
  clone_repo $manifest.source.repo $manifest.source.ref $repo_dir

  run_zig_build $repo_dir $work_dir $manifest.build.zig_version [build install -Doptimize=ReleaseFast --prefix $install_prefix]

  install_stage_file $"($install_prefix)/bin/nvim" $"($stage_dir)/usr/bin/nvim"
  copy_stage_dir $"($install_prefix)/share/nvim" $"($stage_dir)/usr/share/nvim"

  package_stage $stage_dir $dist_file
  let sha_file = (write_sha256 $dist_file)
  announce_output $dist_file $sha_file
}
