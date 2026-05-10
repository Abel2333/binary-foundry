use ./common.nu *

export def install_rust_deps [extra_deps: list<string> = []] {
  let deps = (
    [[cargo clang gcc git lz4-devel make pkgconf-pkg-config rustc tar wayland-devel wayland-protocols-devel] $extra_deps]
      | flatten
      | uniq
  )
  ^dnf install -y ...$deps
}

export def install_zig_deps [extra_deps: list<string> = []] {
  let deps = (
    [[curl findutils gcc gcc-c++ git make tar unzip xz] $extra_deps]
      | flatten
      | uniq
  )
  ^dnf install -y ...$deps
}

export def prepare_anyzig [work_dir: string] {
  let config = (load_config)
  let archive = ([$work_dir "anyzig-x86_64-linux.tar.gz"] | path join)
  let anyzig_dir = ([$work_dir "anyzig-bin"] | path join)
  let anyzig_bin = ([$anyzig_dir "zig"] | path join)
  let anyzig_url = ($config.anyzig_url)

  ^rm -f $archive
  ^rm -rf $anyzig_dir
  ^mkdir -p $anyzig_dir
  ^curl -fsSL $anyzig_url -o $archive
  ^tar xzf $archive -C $anyzig_dir

  if not ($anyzig_bin | path exists) {
    error make { msg: $"anyzig archive did not contain expected zig binary: ($anyzig_bin)" }
  }

  $anyzig_dir
}

export def current_path_string [] {
  let default_system_path = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  let env_columns = ($env | columns)
  let raw_path = (
    if ($env_columns | any {|c| $c == "PATH" }) {
      $env | get PATH
    } else if ($env_columns | any {|c| $c == "Path" }) {
      $env | get Path
    } else {
      $default_system_path
    }
  )

  if (($raw_path | describe | str starts-with "list<")) {
    $raw_path | str join ":"
  } else {
    $raw_path | into string
  }
}

export def run_zig_build [
  repo_dir: string,
  work_dir: string,
  zig_version: string,
  build_args: list<string>
] {
  let anyzig_dir = (prepare_anyzig $work_dir)
  let path_with_anyzig = $"($anyzig_dir):(current_path_string)"

  with-env { PATH: $path_with_anyzig } {
    do {
      cd $repo_dir
      ^zig $zig_version ...$build_args
    }
  }
}

export def run_rust_build [
  repo_dir: string,
  build_args: list<string> = [build --release]
] {
  do {
    cd $repo_dir
    ^cargo ...$build_args
  }
}
