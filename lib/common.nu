export def fail [msg: string] {
  error make { msg: $msg }
}

export def packaging_root [] {
  let cwd = ($env.PWD)
  let local_root = ([$cwd "config.nuon"] | path join)

  if ($local_root | path exists) {
    $cwd
  } else {
    fail "could not locate packaging root; expected config.nuon in the current directory or ./packaging"
  }
}

export def load_config [] {
  open ([(packaging_root) "config.nuon"] | path join)
}

export def manifest_path [name: string] {
  let config = (load_config)
  let manifests_dir = ($config.manifests_dir)
  [ (packaging_root) $manifests_dir $"($name).nuon" ] | path join
}

export def load_manifest [name: string] {
  let path = (manifest_path $name)
  if not ($path | path exists) {
    fail $"missing manifest for asset '($name)': ($path)"
  }
  open $path
}

export def list_assets [] {
  let config = (load_config)
  ls ([(packaging_root) $config.manifests_dir] | path join)
    | where type == file
    | get name
    | where ($it | str ends-with ".nuon")
    | each {|name| $name | path parse | get stem }
    | sort
}

export def asset_config [name: string] {
  let asset = (
    try {
      load_manifest $name
    } catch {
      null
    }
  )
  if ($asset | is-empty) {
    let names = (list_assets | str join ", ")
    fail $"unknown asset '($name)'; available: ($names)"
  }
  $asset
}

export def render_artifact_name [template: string, fedora_version: string, target_arch: string] {
  $template
    | str replace "{fedora_version}" $fedora_version
    | str replace "{target_arch}" $target_arch
}

export def ensure_dir [dir: string] {
  mkdir $dir
}

export def reset_dir [dir: string] {
  ^rm -rf $dir
  mkdir $dir
}

export def clone_repo [repository: string, branch: string, dest: string] {
  ^rm -rf $dest
  if ($branch | is-empty) {
    ^git clone --depth 1 $repository $dest
  } else {
    ^git clone --depth 1 --branch $branch $repository $dest
  }
}

export def sha256_file [file: string] {
  (^sha256sum $file | split row " " | first)
}

export def package_stage [stage_dir: string, dist_file: string] {
  ^tar czf $dist_file -C $stage_dir .
}

export def write_sha256 [dist_file: string] {
  let sha_file = $"($dist_file).sha256"
  let artifact_name = ($dist_file | path basename)
  $"(sha256_file $dist_file)  ($artifact_name)" | save -f $sha_file
  $sha_file
}

export def announce_output [dist_file: string, sha_file: string] {
  print $"packaging: wrote ($dist_file)"
  print $"packaging: wrote ($sha_file)"
}

export def install_stage_file [source: string, dest: string] {
  ^install -Dm755 $source $dest
}

export def copy_stage_dir [source: string, dest: string] {
  ^mkdir -p $dest
  ^cp -a $"($source)/." $dest
}

export def apply_patch_files [repo_dir: string, patch_files: list<string>] {
  if (($patch_files | length) == 0) {
    return
  }

  do {
    cd $repo_dir
    for patch_file in $patch_files {
      ^git apply --verbose $patch_file
    }
  }
}
