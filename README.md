lncm/docker-lnd
================

![Build Status]
[![gh_last_release_svg]][gh_last_release_url]
[![Docker Image Size]][lnd-docker-hub]
[![Docker Pulls Count]][lnd-docker-hub]

[Build Status]: https://github.com/lncm/docker-lnd/workflows/Build%20%26%20deploy%20tag/badge.svg

[gh_last_release_svg]: https://img.shields.io/github/v/release/lncm/docker-lnd?sort=semver
[gh_last_release_url]: https://github.com/lncm/docker-lnd/releases/latest

[Docker Image Size]: https://img.shields.io/microbadger/image-size/lncm/lnd.svg
[Docker Pulls Count]: https://img.shields.io/docker/pulls/lncm/lnd.svg?style=flat
[lnd-docker-hub]: https://hub.docker.com/r/lncm/lnd


This repo builds [`lnd`] in a completely reproducible, and auditable way, and packages it into radically minimal Docker containers provided for various CPU architectures and in various variants.

[`lnd`]: https://github.com/lightningnetwork/lnd

#### Details

* **All [`git-tags`]** <small>(and most commits)</small> **are signed** by `D8CA1776EB9265491D07CE67F546ECBEA809CB18` 
* **All [`git-tags`]** <small>(and most commits)</small> **are [`opentimestamps`]-ed**
* **All builds are fully reproducible.**  Each `Dockerfile` builds `lnd` twice: once on [Alpine], and once on [Debian], and the result binaries are [compared against each other] before proceeding
* Each build produces binaries for: `amd64`, `arm64v8`, `arm32v7`, and `arm32v6`
* Some Docker Images are also provided in different variants, ex: `monitoring` (enables Prometheus monitoring), or `experimental` (enables options disabled by default)  
* All architectures are aggregated under an easy-to-use [Docker Manifest]
* All [`git-tags`] are [build automatically], and with an [auditable trace]
* Each successful build of a `git tag` pushes result Docker image to [Docker Hub]
* Each successful build of a `git tag` uploads result Go binaries to [Github Releases]
* Images pushed to Docker Hub are never deleted (even if `lnd` version gets overriden, previous one is preserved)
* All `final` images are based on Alpine for minimum base size
* All binaries are [compressed with `upx`]
* Each `git-tag` build is tagged with a unique tag number
* Each _minor_ version is stored in a separate directory (for the ease of backporting patches)


[`git-tags`]: https://github.com/lncm/docker-lnd/tags
[`opentimestamps`]: https://github.com/opentimestamps/opentimestamps-client/blob/master/doc/git-integration.md#usage
[Alpine]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/0.8/Dockerfile#L58-L78
[Debian]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/0.8/Dockerfile#L84-L101
[compared against each other]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/0.8/Dockerfile#L125-L127
[Docker Manifest]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/.github/workflows/on-tag.yml#L262-L283
[build automatically]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/.github/workflows/on-tag.yml
[auditable trace]: https://github.com/lncm/docker-lnd/commit/bc3bae42a51eb565caa7c910ae8a5c832f087669/checks?check_suite_id=354878751
[Docker Hub]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/.github/workflows/on-tag.yml#L259-L260
[Github Releases]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/.github/workflows/on-tag.yml#L297-L305
[compressed with `upx`]: https://github.com/lncm/docker-lnd/blob/3a26bc667c441e94958b876170f87d538cb5a07a/0.8/Dockerfile#L134-L135

## Tags

* [`v0.8.0` (`+build7`)][build7] - currently _latest_ version of `lnd` (see [log][log7])
    * `v0.8.0-amd64`,  `v0.8.0.arm64`, `v0.8.0-arm32v7`, `v0.8.0-arm32v6`
* [`v0.8.0-monitoring` (`+build9`)][build9] - latest version of lnd with [monitoring] enabled (see [log][log9])
* [`v0.7.1` (`+build11`)][build11] (see [log][log11])


[build7]: https://github.com/lncm/docker-lnd/releases/tag/v0.8.0%2Bbuild7    
[log7]: https://github.com/lncm/docker-lnd/runs/262864700

[build9]: https://github.com/lncm/docker-lnd/releases/tag/v0.8.0-monitoring%2Bbuild9
[log9]: https://github.com/lncm/docker-lnd/runs/262901705
[monitoring]: https://github.com/lightningnetwork/lnd/blob/v0.8.0-beta/monitoring/monitoring_on.go

[build11]: https://github.com/lncm/docker-lnd/releases/tag/v0.7.1%2Bbuild11
[log11]: https://github.com/lncm/docker-lnd/runs/263056982


## Usage

### Pull

First pull the image from [Docker Hub]:

```bash
docker pull lncm/lnd:v0.8.2
```

> **NOTE:** Running above will automatically choose native architecture of your CPU.

[Docker Hub]: https://hub.docker.com/r/lncm/lnd

Or, to pull a specific CPU architecture:

```bash
docker pull lncm/lnd:v0.8.2-arm64
```

#### Start

Then to start lnd, execute:

```bash
docker run -it --rm \
    -v ~/.lnd:/root/.lnd \
    -p 9735:9735 \
    -p 10009:10009 \
    --name lnd \
    --detach \
    lncm/lnd:v0.8.2
```

That will runs `lnd` with:

* all data generated by the container is stored in `~/.lnd` **on your host machine**,
* port `9735` will be reachable for the peer-to-peer communication,
* port `10009` will be reachable for the RPC communication,
* created container will get named `lnd`,
* that command will run the container in the background and print the ID of the container being run.


#### Interact

To issue any commands to a running container, do:

```bash
docker exec -it lnd BINARY COMMAND
```

Where:
* `BINARY` is either `lnd` or `lncli`, and
* `COMMAND` is something you'd normally pass to the binary   

Examples:

```bash
docker exec -it lnd  lnd --help
docker exec -it lnd  lnd --version
docker exec -it lnd  lncli --help
docker exec -it lnd  lncli getinfo
docker exec -it lnd  lncli getnetworkinfo
```


## Releases

After `git-tag` push, the release process is fully automated.  That being said there are a few things that need to be done to prepare for the release.

### Patch Release 

In case of a patch release (v0.0.X), it's enough to edit `TAG` variable in appropriate `Dockerfile`, commit, and run `./scripts/release.sh …`.

Ex. If `lnd` gets updated from `v0.6.0-beta` to `v0.6.1-beta`, it's _usually_ enough to open `0.6/Dockerfile`, update [this line] with the new tag, commit, and run:

```shell script
./scripts/new-release.sh v0.6.1-beta
```

> **NOTE:** The `release.sh` scripts ensures that correct version is set in the relevant `Dockerfile`, as well as that correct build tag is used.

[this line]: https://github.com/lncm/docker-lnd/blob/master/0.6/Dockerfile#L17

### Major/Minor release


This releases might bring changes that are not backwards compatible.  To have separation, it's recommended to create `MAJOR.MINOR/` directory at repo's root, copy `Dockerfile` from the previous version, and follow the steps described in [Patch Release].

[Patch Release]: #Patch-Release 

### Trigger

To trigger build of new-multi arch release, run `./scripts/release.sh …`.  After a few minutes the new version should show up on Docker Hub. 
