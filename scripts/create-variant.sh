#!/usr/bin/env bash

set -eo pipefail

#
## This scripts turns all uncommitted changes in a minor-version repository into a `*.patch` file that can be used as a variant.
#

SCRIPT_NAME=$(basename "$0")
BASE_PATH="$(dirname "$(dirname "$(realpath "$0")")")"

main() {
  declare dir="$1" name="$2"

  # Make sure required arguments are passed to the script
  if [[ -z "$dir" ]] || [[ -z "$name" ]]; then
    >&2 printf "./%s: <directory> <variant-name>\n" "$SCRIPT_NAME"
    exit 1
  fi

  # Make sure subversion directory exists
  if [[ ! -d "$BASE_PATH/$dir" ]]; then
    >&2 printf "./%s: <directory> doesn't exist\n" "$SCRIPT_NAME"
    exit 1
  fi

  local patchfile
  patchfile="variant-$name.patch"

  git diff --minimal --no-prefix --relative="$dir" > "/tmp/$patchfile"

  # Make sure generated patch is not empty
  if [[ ! -s "/tmp/$patchfile" ]]; then
    >&2 printf "./%s: No changes found in %s\n" "$SCRIPT_NAME" "$dir"
    exit 1
  fi

  # If variant with same name exists, ask for confirmation before overriding
  if git ls-files --error-unmatch "$dir/$patchfile" &>/dev/null; then
    read -p "This variant already exists (will be lost, if it wasn't applied).  Override?  [yn] " -n 1 -r
    echo
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        >&2 printf "./%s: Aborting w/o applying any changes\n" "$SCRIPT_NAME"
        exit 1
    fi
  fi

  mv -f  "/tmp/$patchfile"  "$dir/"

  git add "$dir/$patchfile"
  git commit -m "Added: $dir/$patchfile"
  git checkout -- "$dir/Dockerfile"
}

main "$@"
