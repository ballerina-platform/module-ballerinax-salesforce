#!/bin/bash

BAL_EXAMPLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAL_CENTRAL_DIR="$HOME/.ballerina/repositories/central.ballerina.io/"
BAL_HOME_DIR="$BAL_EXAMPLES_DIR/../ballerina"

set -e

case "$1" in
build)
  BAL_CMD="build"
  ;;
run)
  BAL_CMD="run"
  ;;
*)
  echo "Invalid command provided: '$1'. Please provide 'build' or 'test' as the command."
  exit 1
  ;;
esac

VERSION="$2"

# Read Ballerina package name
BAL_PACKAGE_NAME=$(awk -F'"' '/^name/ {print $2}' "$BAL_HOME_DIR/Ballerina.toml")

# Push the package to the local repository
cd "$BAL_HOME_DIR" &&
  bal pack &&
  bal push --repository=local

# Remove the cache directories in the repositories
cacheDirs=($(ls -d "$BAL_CENTRAL_DIR"/cache-* 2>/dev/null))
for dir in "${cacheDirs[@]}"; do
  [ -d "$dir" ] && rm -r "$dir"
done
echo "Successfully cleaned the cache directories"

# Update the central repository
BAL_DESTINATION_DIR="$HOME/.ballerina/repositories/central.ballerina.io/bala/ballerinax/$BAL_PACKAGE_NAME"
BAL_SOURCE_DIR="$HOME/.ballerina/repositories/local/bala/ballerinax/$BAL_PACKAGE_NAME"
[ -d "$BAL_DESTINATION_DIR" ] && rm -r "$BAL_DESTINATION_DIR"
[ -d "$BAL_SOURCE_DIR" ] && cp -r "$BAL_SOURCE_DIR" "$BAL_DESTINATION_DIR"
echo "Successfully updated the local central repositories"


# Loop through examples in the examples directory
cd "$BAL_EXAMPLES_DIR"
for dir in $(find "$BAL_EXAMPLES_DIR" -type d -maxdepth 2  -mindepth 2); do
  # Skip the build directory
  if [[ "$dir" == *libs ]] || [[ "$dir" == *tmp ]]; then
    continue
  fi
  (cd "$dir" && sed -i "s/version =.*/version = \""$VERSION"\" /g" Ballerina.toml && bal "$BAL_CMD" --offline && cd ..);
done