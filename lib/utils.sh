#!/usr/bin/env bash

function print_heading {
  echo ""
  echo "-----> $*"
}

function print_indented {
  echo "       $*"
}

function print_error {
  echo -e "$(print_indented "\033[0;31mError: ${*}\033[0m")"
}

function print_success {
  echo -e "$(print_indented "\033[0;32m${*}\033[0m")"
}

function read_indented {
  while read -r LINE; do
    print_indented "$LINE" || true
  done
}

function print_configuration {
  local config_file
  config_file="$1"

  print_indented "--------------"
  cat "$config_file" | read_indented
  print_indented "--------------"
}

function clean {
  local build_path
  local cache_path
  local env_path
  local heroku_path
  local assets_paths_string

  build_path="$1"
  cache_path="$2"
  env_path="$3"
  heroku_path="$4"
  assets_paths_string="$5"

  print_indented "Cleaning heroku build directory..."
  rm -rf "${heroku_path}/node"

  print_indented "Cleaning cache directory..."
  rm -rf "${cache_path}"/*

  print_indented "Cleaning env directory..."
  rm -rf "${env_path}"/*

  IFS=', ' read -r -a assets_paths <<< "$assets_paths_string"

  for assets_path in "${assets_paths[@]}"; do
    app_modules="${build_path}/${assets_path}/node_modules"
    if [[ -d "$app_modules" ]]; then
      print_indented "Cleaning ${app_modules}..."
      rm -rf "$app_modules"
    fi
  done

  print_success "Clean as a whistle!"
}

function get_app_name {
  local package_root
  package_root="$1"

  echo "$(basename $(dirname "$package_root"))"
}
