## Scripts

### `./create-variant.sh`

This script helps create/update a patch of a specific minor version.

#### Create 

To **create** a `majestic` variant of a `v0.9.x` version:

1. Apply all necessary changes to `0.9/Dockerfile`
1. Run: `./scripts/create-variant.sh 0.9 majestic`
1. Observe `0.9/variant-majestic.patch` created & committed
1. Push changes

#### Update

To **update** a `monitoring` variant of a `0.9` version:

1. Apply current patch with sth like: `patch --no-backup-if-mismatch -d 0.9 < 0.9/variant-monitoring.patch`
1. Apply all extra changes
1. Run: `./scripts/create-variant.sh 0.9 monitoring`
1. Confirm override
1. Verify changes to `0.9/variant-monitoring.patch`
1. Push changes


### `./new-release.sh`

This scripts helps with releases of new versions, by verifying the correct version is set in the `Dockerfile`, and setting the correct build number.

Example: to release `v0.9.0` in `experimental` variant:

1. Update relevant dockerfile: `0.9/Dockerfile`
1. Make sure new version is set in the said file as `ARG VERSION=v0.9.0`
1. Make sure all changes are committed
1. Run `./scripts/new-release.sh v0.9.0 experimental`
1. See new build job show up in https://github.com/lncm/docker-lnd/actions


### `./verify-patches.sh`

This job verifies if all patches apply cleanly.

To verify all, run: `./scripts/verify-patches.sh`

To verify only specific minor version: `./scripts/verify-patches.sh 0.9`
