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
  local cache_path
  cache_path="$1"

  if [[ "$clear_cache" == "true" ]]; then
    print_heading "Cleaning cache directory..."
    rm -rf "${cache_path}"/*

    print_success "Clean as a whistle!"
  fi

}

function get_app_name {
  local package_root
  package_root="$1"

  echo "$(basename $(dirname "$package_root"))"
}
