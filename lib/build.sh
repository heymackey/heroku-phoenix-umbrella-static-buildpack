#!/usr/bin/env bash

download_node() {
  local platform=linux-x64
  local node_src_path
  local node_version

  node_src_path="$1"
  node_version="$2"

  print_heading "Resolving node@${node_version}..."

  if [[ ! -f "${node_src_path}" ]]; then
    if ! read -r number url < <(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=$node_version" "https://nodebin.herokai.com/v1/node/$platform/latest.txt"); then
      print_error "No version found for node@${node_version}"
    fi

    print_indented "Downloading and installing node $number..."

    local response_code
    response_code=$(curl "$url" -L --silent --fail --retry 5 --retry-max-time 15 -o ${node_src_path} --write-out "%{http_code}")

    if [ "$response_code" != "200" ]; then
      echo "Unable to download node@${node_version}: status $response_code" && false
    fi
  else
    print_indented "Using cached node@${node_version}..."
  fi
}

install_node() {
  local node_src_path
  local node_build_path

  node_src_path="$1"
  node_build_path="$2"
  print_heading "Installing node@${node_version}..."

  if [[ -d "$node_build_path" ]]; then
    print_error "node@${node_version} is already install in $node_build_path"
    print_indented "Please remove any prior buildpack that installs Node."
    exit 1
  else
    mkdir -p "$node_build_path"
    tar xzf "$node_src_path" -C /tmp
    mv /tmp/node-v"$node_version"-linux-x64/* "$node_build_path"
    chmod +x "$node_build_path"/bin/*
    PATH="${node_build_path}/bin:$PATH"
    print_success "node@${node_version} installed!"
  fi
}

function install_npm {
  local build_dir
  local npm_version
  npm_version="$2"
  build_dir="$1"

  print_heading "Installing npm..."

  if [[ ! "$npm_version" ]] || [[ "$(npm --version)" == "$npm_version" ]]; then
    print_indented "Using default npm version"
  else
    print_indented "Downloading and installing npm $npm_version (replacing version $(npm --version))..."
    cd "$build_dir" || exit 1
    npm install --unsafe-perm --quiet -g npm@"$npm_version" 2>&1 >/dev/null | read_indented
    print_success "npm installed!"
  fi

}

function cache_npm_dependencies {
  local module_cache
  local cache_root
  local app_name
  local package_root
  local module_root

  package_root="$1"
  cache_root="$2"
  app_name="$(get_app_name "$package_root")"
  module_cache="${cache_root}/${app_name}/node_modules"
  module_root="${package_root}/node_modules"

  print_heading "Caching dependencies for $app_name"

  mkdir -p "$module_cache"
  cp -r "$module_root" "$module_cache"

  print_indented "Done."
}

function install_npm_dependencies {
  local package_root
  local app_name

  package_root="$1"
  app_name=$(get_app_name "$package_root")

  print_heading "Installing package dependencies for $app_name"

  cd "$package_root"

  npm prune | read_indented
  npm install --quiet --unsafe-perm 2>&1 | read_indented
  npm rebuild 2>&1 | read_indented
  npm --unsafe-perm prune 2>&1 | read_indented

  print_success "$app_name dependencies installed."
}

function load_config {
  print_heading "Loading config..."

  local root_path="$1"
  local build_path="$2"
  local custom_config_file
  local default_config_file
  local config_file

  custom_config_file="${build_path}/phoenix_static_assets_buildpack.config"
  default_config_file="${root_path}/phoenix_static_assets_buildpack.config"

  if [[ -f "$custom_config_file" ]]; then
    config_file="$custom_config_file"
    print_indented "Custom configuration loaded."
    print_configuration "$custom_config_file"
  fi

  if [[ ! -f "$custom_config_file" ]] && [[ -f "$default_config_file" ]]; then
    config_file="$default_config_file"
    print_indented "No custom config file. Using default configuration."
    print_configuration "$default_config_file"
  fi

  if [[ ! -f "$custom_config_file" ]] && [[ ! -f "$default_config_file" ]]; then
    echo print_error"No configuration found!"
    exit 1
  fi

  source "$config_file"

  print_indented "Configuration loaded."
}

function export_config_vars {
  print_heading "Exporting config variables..."

  local env_dir
  local whitelist_regex
  local blacklist_regex

  env_dir="$1"
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}

  if [ -d "$env_dir" ]; then
    print_indented "Exporting the following config vars:"
    for e in ${env_dir}/*; do
      echo "$e" | grep -E "$whitelist_regex" | grep -vE "$blacklist_regex" &&
      export "$e=$(cat "${env_dir}/${e}")"
      :
    done
  fi
}

export_mix_env() {
  print_heading "Exporting MIX_ENV..."

  if [ -z "${MIX_ENV}" ]; then
    if [ -d "$env_dir" ] && [ -f "$env_dir/${MIX_ENV}" ]; then
      export MIX_ENV
      MIX_ENV=$(cat "${env_dir}/${MIX_ENV}")
    else
      export MIX_ENV=prod
    fi
  fi

  print_indented "* MIX_ENV=${MIX_ENV}"
}

function validate_assets_path {
  local assets_path
  assets_path="$1"

  if [[ -f "${assets_path}/package.json" ]]; then
    print_success "☑ Found ${assets_path}/package.json"
  else
    print_error "$assets_path not found!"
    exit 1
  fi
}

function validate_assets_paths {
  print_heading "Validating asset paths..."

  local assets_paths_string
  local assets_paths

  assets_paths_string="$1"
  IFS=', ' read -r -a assets_paths <<< "$assets_paths_string"

  for assets_path in "${assets_paths[@]}"; do
    validate_assets_path "${build_path}/$assets_path"
  done
}

function default_phoenix_deploy {
  local package_root
  local app_path

  package_root="$1"
  app_path="$2"

  cd "$package_root"

  npm run deploy | read_indented

  cd "$app_path"

  mix phx.digest
  mix phx.digest.clean
}
