# This project is deprecated for [lightning labs lnd containers](https://hub.docker.com/r/lightninglabs/lnd/tags)

Upgrade according

## Sample docker compose

```
version: '3.8'
services:
        web:
                image: nginx:1.17.8
                container_name: web
                volumes:
                        - ${PWD}/nginx:/etc/nginx
                restart: on-failure
                ports:
                    - "80:80"
                stop_grace_period: 30s
                networks:
                    net:
                        ipv4_address: 10.254.1.2
        bitcoin:
                image: lncm/bitcoind:v0.21.0
                container_name: bitcoin
                volumes:
                        - ${PWD}/bitcoin:/root/.bitcoin
                        - ${PWD}/bitcoin:/data/.bitcoin
                        - ${PWD}/bitcoin:/data/bitcoin
                restart: on-failure
                ports:
                    - "8333:8333"
                    - "8332:8332"
                stop_grace_period: 20m30s
                networks:
                    net:
                        ipv4_address: 10.254.2.2
        lnd:
                image: lightninglabs/lnd:v0.13.1-beta@sha256:f26ddbbea3f7bad45d994e6258b8198acaebf65e575eedf2a566d04f0c1fb9d9
                user: 1000:1000
                container_name: lnd
                volumes:
                        - ${PWD}/lnd:/data/.lnd
                        - ${PWD}/lnd:/root/.lnd
                        - ${PWD}/bitcoin:/root/.bitcoin
                        - ${PWD}/bitcoin:/data/.bitcoin
                        - ${PWD}/secrets/lnd-password.txt:/data/.lnd/walletpassword
                        - ${PWD}/secrets/lnd-password.txt:/root/.lnd/walletpassword
                restart: on-failure
                ports:
                    - "9735:9735"
                    - "10009:10009"
                environment:
                    HOME: /data
                depends_on: [ bitcoin, web ]
                stop_grace_period: 10m30s
                networks:
                    net:
                        ipv4_address: 10.254.2.3
        invoicer:
                image: "lncm/invoicer:v0.8.1"
                container_name: invoicer
                depends_on: [ bitcoin, lnd ]
                restart: on-failure
                stop_grace_period: 30s
                volumes:
                        - "${PWD}/invoicer:/data"
                        - "${PWD}/lnd:/lnd"
                networks:
                    net:
                        ipv4_address: 10.254.2.4
        neutrino-switcher:
                image: "lncm/neutrino-switcher:1.0.4"
                container_name: neutrino-switcher
                depends_on: [ lnd, bitcoin ]
                restart: always
                volumes:
                    - "${PWD}/lnd:/lnd"
                    - "${PWD}/secrets:/secrets"
                    - "${PWD}/statuses:/statuses"
                    - "/var/run/docker.sock:/var/run/docker.sock"
                environment:
                    JSONRPCURL: http://10.254.2.2:8332
                    LND_CONTAINER_NAME: lnd
                    SLEEPTIME: 43200
                networks:
                    net:
                        ipv4_address: 10.254.2.6
        tor:
                image: "lncm/tor:0.4.6.7@sha256:472c8d1265679e7cfd641edcbc44ec2fa0e500f6929bd8dc1f4811feffcfefaa"
                container_name: tor
                restart: on-failure
                volumes:
                    - "${PWD}/tor/torrc:/etc/tor/torrc"
                    - "${PWD}/tor/data:/var/lib/tor/"
                    - "${PWD}/tor/run:/var/run/tor/"
                networks:
                    net:
                        ipv4_address: 10.254.1.3

networks:
    net:
        ipam:
            driver: default
            config:
                - subnet: 10.254.0.0/16

```

lncm/lnd
========

![Build Status]
[![gh_last_release_svg]][gh_last_release_url]
[![Docker Image Size]][lnd-docker-hub]
[![Docker Pulls Count]][lnd-docker-hub]

[Build Status]: https://github.com/lncm/docker-lnd/workflows/Build%20%26%20deploy%20on%20git%20tag%20push/badge.svg

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

> **NOTE:** For an always up-to-date list see: https://hub.docker.com/r/lncm/lnd/tags

* `v0.13.0` `v0.13.0-monitoring` `v0.13.0-experimental` `v0.13.0-etcd`
* `v0.12.0` `v0.12.0-monitoring` `v0.12.0-experimental` `v0.12.0-etcd`
* `v0.11.1` `v0.11.1-monitoring` `v0.11.1-experimental` `v0.11.1-etcd`
* `v0.11.0` `v0.11.0-monitoring` `v0.11.0-experimental` `v0.11.0-etcd`
* `v0.10.4` `v0.10.4-monitoring` `v0.10.4-experimental`
* `v0.10.3`
* `v0.10.2`
* `v0.10.1` `v0.10.1-root-experimental` `v0.10.1-monitoring` `v0.10.1-experimental`
* `v0.10.0` `v0.10.0-root-experimental` `v0.10.0-monitoring` `v0.10.0-experimental`
* `v0.9.2` `v0.9.2-root-experimental` `v0.9.2-monitoring` `v0.9.2-experimental`
* `v0.9.1` `v0.9.1-root-experimental` `v0.9.1-monitoring` `v0.9.1-experimental`
* `v0.9.0` `v0.9.0-monitoring` `v0.9.0-experimental`
* `v0.8.2` `v0.8.2-monitoring` `v0.8.2-experimental`
* `v0.8.1` `v0.8.1-monitoring` `v0.8.1-experimental`
* `v0.8.0` `v0.8.0-monitoring` `v0.8.0-experimental` `v0.8.0-bitcoind-0.19`
* `v0.7.1` `v0.7.1-monitoring`
* `v0.7.0`
* `v0.6.1`
* `v0.5.2`

## Usage

### Pull

First pull the image from [Docker Hub]:

```bash
docker pull lncm/lnd:v0.11.0
```

> **NOTE:** Running above will automatically choose native architecture of your CPU.

[Docker Hub]: https://hub.docker.com/r/lncm/lnd

Or, to pull a specific CPU architecture:

```bash
docker pull lncm/lnd:v0.11.0-arm64v8
```

#### Start

Then to start lnd, run:

```bash
# Create a folder called ~/.lnd
mkdir -p $HOME/.lnd/
# Then copy a config file into ~/.lnd
wget -qO $HOME/.lnd/lnd.conf https://raw.githubusercontent.com/lightningnetwork/lnd/v0.11.1-beta/sample-lnd.conf

# Run docker
docker run  -it  --rm  --detach \
    -v ~/.lnd:/data/.lnd \
    -p 9735:9735 \
    -p 10009:10009 \
    --name lnd \
    lncm/lnd:v0.11.0
```

That will runs `lnd` with:

* all data generated by the container is stored in `~/.lnd` **on your host machine**,
* all data is created as owned by used with `UID` `1000`
* port `9735` is reachable on the localhost for the peer-to-peer communication,
* port `10009` is reachable on the localhost for RPC communication,
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

In case of a patch release (v0.0.X), it's enough to edit `VERSION` variable in appropriate `Dockerfile`, commit, and run `./scripts/new-release.sh …`.

Ex. If `lnd` gets updated from `v0.6.0-beta` to `v0.6.1-beta`, it's _usually_ enough to open `0.6/Dockerfile`, update [this line] with the new tag, commit, and run:

```shell script
./scripts/new-release.sh v0.13.0
# in case of other patches
./scripts/new-release.sh v0.13.0 experimental
```

> **NOTE:** The `new-release.sh` scripts ensures that correct version is set in the relevant `Dockerfile`, as well as that correct build tag is used.

[this line]: https://github.com/lncm/docker-lnd/blob/master/0.6/Dockerfile#L4


### Major/Minor release

This releases might bring changes that are not backwards compatible.  To have separation, it's recommended to create `MAJOR.MINOR/` directory at repo's root, copy `Dockerfile` from the previous version, and follow the steps described in [Patch Release].

One additional thing to be done here, is adding a new entry to `matrix.ver` in [`test.yml`] file to make sure that newly added version is being tested.

[`test.yml`]: https://github.com/lncm/docker-lnd/blob/c0f8ee34cab1f39c92e3ef31a7c70ce63b8e2ba9/.github/workflows/test.yml#L21-L26

[Patch Release]: #Patch-Release 

### Trigger

To trigger build of new-multi arch release, run `./scripts/new-release.sh …`.  After a few minutes the new version should show up on Docker Hub. 
