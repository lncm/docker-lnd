#!/bin/bash
set -e

# required version
VERSION=$1

# Optional variant
VARIANT=$2

# Verify version to-be-released is provided
if [[ -z "${VERSION}" ]]; then
  >&2 printf "\nERR: version missing:  version needs to be passed as the first argument.  Try:\n"
  >&2 printf "\t./%s  %s\n\n"   "$(basename "$0")"  "v0.8.1"
  exit 1
fi

# Get directory
DIR="$(echo "${VERSION}" | tr -d v | cut -d. -f-2)"

# If variant is provided, verify it exists
if [[ -n "${VARIANT}" ]] && [[ ! -f "${DIR}/variant-${VARIANT}.patch" ]]; then
  >&2 printf "\nERR: missing variant:  variant passed as the 2nd argument, bu corresponding patch file is not present.  Try:\n"
  >&2 printf "\t./%s  %s  %s\n\n"   "$(basename "$0")"  "v0.8.1"  "monitoring"
  exit 1
fi

# Verify there's no uncommitted changes in the working dir
if [[ -n "$(git status --untracked-files=no --porcelain)" ]]; then
  >&2 printf "\nERR: working directory not clean.  Commit, or stash changes to continue.\n\n"
  exit 1
fi

if ! grep -q "${VERSION}" "${DIR}/Dockerfile" ; then
  >&2 printf "\nERR: Requested version not present in Dockerfile. Make sure that's what you want to do.\n\n"
  exit 1
fi

git fetch --tags

# Get last build number
LAST=$(git tag | grep '+build' | sed 's|^.*build||' | sort -h | tail -n 1)

# Increment it
((LAST++))


TAG="${VERSION}"

if [[ -n "${VARIANT}" ]]; then
  TAG="${TAG}-${VARIANT}"
fi

TAG="${TAG}+build${LAST}"


printf "Creating tag: %s…\t" "${TAG}"

git tag -sa "${TAG}" -m "${TAG}"

echo "done"


printf "Pushing tag: %s…\t" "${TAG}"

git push origin "${TAG}"

echo "All done"
