#!/usr/bin/env nu

use ../lib/common.nu *

def sha_from_file [path: string] {
  open $path | lines | first | split row " " | first
}

def main [
  --fedora-version: string,
  --target-arch: string,
  --release-tag: string
] {
  let config = (load_config)
  let fedora_version = ($fedora_version | default $config.fedora_version)
  let target_arch = ($target_arch | default $config.target_arch)
  let release_tag = ($release_tag | default "snapshot-local")
  let dist_dir = ($config.dist_dir)

  let assets = (
    list_assets | each {|name|
      let manifest = (asset_config $name)
      let artifact = (render_artifact_name $manifest.output.artifact $fedora_version $target_arch)
      let artifact_path = ([$dist_dir $artifact] | path join)
      let sha_path = $"($artifact_path).sha256"

      if not ($artifact_path | path exists) {
        fail $"missing artifact for asset '($name)': ($artifact_path)"
      }
      if not ($sha_path | path exists) {
        fail $"missing sha256 file for asset '($name)': ($sha_path)"
      }

      {
        name: $name
        file: $artifact
        sha256: (sha_from_file $sha_path)
        source: $manifest.source
        build: $manifest.build
      }
    }
  )

  let manifest = {
    release_tag: $release_tag
    fedora_version: $fedora_version
    target_arch: $target_arch
    assets: $assets
  }

  let output_path = ([$dist_dir "manifest.json"] | path join)
  $manifest | to json --indent 2 | save -f $output_path
  print $"packaging: wrote ($output_path)"
}
