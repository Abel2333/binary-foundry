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
  let manifest = (asset_config "aria2")
  let make_jobs = ((sys cpu | length) | into string)
  install_autotools_deps [c-ares-devel libssh2-devel libxml2-devel openssl-devel sqlite-devel zlib-devel]

  let repo_dir = ([$work_dir "aria2"] | path join)
  let stage_dir = ([$work_dir "stage"] | path join)
  let artifact_name = (render_artifact_name $manifest.output.artifact $fedora_version $target_arch)
  let dist_file = ([$dist_dir $artifact_name] | path join)

  reset_dir $stage_dir
  clone_repo $manifest.source.repo $manifest.source.ref $repo_dir

  run_autotools_build $repo_dir [
    --prefix=/usr
    --disable-dependency-tracking
    --with-openssl
  ] [
    -j
    $make_jobs
  ]

  do {
    cd $repo_dir
    with-env { DESTDIR: $stage_dir } {
      ^make install
    }
  }

  package_stage $stage_dir $dist_file
  let sha_file = (write_sha256 $dist_file)
  announce_output $dist_file $sha_file
}
