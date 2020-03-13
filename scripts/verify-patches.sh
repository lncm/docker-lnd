#!/usr/bin/env bash

set -eo pipefail

#
## This script verifies if all variant patches apply cleanly
#

dir=${1:-0.*}

# shellcheck disable=SC2086
if ! ls $dir/variant-*.patch &>/dev/null; then
    echo "No variants found. Skipping."
    exit 0
fi

exit_code=0

# shellcheck disable=SC2231
for file in $dir/variant-*.patch; do
  printf "\nChecking: %s…\n" "$file"

  dir="$(dirname "$file")"

  patch -d "$dir" --dry-run < "$file" && { echo "OK" && continue; }

  echo "FAIL"
  exit_code=1
done

exit "$exit_code"
