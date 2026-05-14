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
  let manifest = (asset_config "awww")
  install_rust_deps

  let repo_dir = ([$work_dir "awww"] | path join)
  let stage_dir = ([$work_dir "stage"] | path join)
  let artifact_name = (render_artifact_name $manifest.output.artifact $fedora_version $target_arch)
  let dist_file = ([$dist_dir $artifact_name] | path join)

  reset_dir $stage_dir
  clone_repo $manifest.source.repo $manifest.source.ref $repo_dir

  run_rust_build $repo_dir [build --release]

  install_stage_file $"($repo_dir)/target/release/awww" $"($stage_dir)/usr/bin/awww"
  install_stage_file $"($repo_dir)/target/release/awww-daemon" $"($stage_dir)/usr/bin/awww-daemon"

  package_stage $stage_dir $dist_file
  let sha_file = (write_sha256 $dist_file)
  announce_output $dist_file $sha_file
}
