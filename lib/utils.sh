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
  local assets_paths_string
  assets_path_string="$1"
  IFS=', ' read -r -a assets_paths <<< "$assets_paths_string"
  for assets_path in "${assets_paths[@]}"; do
    if [[ -d "${assets_path}/node_modules" ]]; then
      print_indented "Clean ${assets_path}/node_modules"
      # rm -rf "${assets_path}/node_modules"
    else
      print_indented "Don't clean ${assets_path}/node_modules"
    fi
  done
}

function get_app_name {
  local package_root
  package_root="$1"

  echo "$(basename $(dirname "$package_root"))"
}
