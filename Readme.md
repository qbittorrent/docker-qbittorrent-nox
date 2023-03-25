# qBittorrent-nox Docker Image [![GitHub Actions CI Status](https://github.com/qbittorrent/docker-qbittorrent-nox/actions/workflows/release.yaml/badge.svg)](https://github.com/qbittorrent/docker-qbittorrent-nox/actions)

Repository on Docker Hub: https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox \
Repository on GitHub: https://github.com/qbittorrent/docker-qbittorrent-nox

## Supported architectures

* linux/amd64
* linux/arm/v6
* linux/arm/v7
* linux/arm64/v8

## Reporting bugs

If the problem is related to Docker, please report it to this repository: \
https://github.com/qbittorrent/docker-qbittorrent-nox/issues

If the problem is with qBittorrent, please report the issue to its main repository: \
https://github.com/qbittorrent/qBittorrent/issues

## Usage

0. Prerequisites

    In order to run this image you'll need Docker installed: https://docs.docker.com/get-docker/

    If you don't need the GUI, you can just install Docker Engine: https://docs.docker.com/engine/install/

    It is also recommended to install Docker Compose as it can significantly ease the process: https://docs.docker.com/compose/install/

1. Download this repository

    You can either `git clone` this repository or download an .zip of it: https://github.com/qbittorrent/docker-qbittorrent-nox/archive/refs/heads/main.zip

2. Edit Docker environment file

    If you are not using Docker Compose you can skip editing the environment file.
    However the variables presented below is crucial in later steps, make sure you understand them.

    Find and open the `.env` file in the repository you cloned (or the .zip archive you downloaded). \
    There are a few variables that you must take care of before you can run the image. \
    You can find the meanings of these variables in the following section. Make sure you understand every one of them.

    #### Environment variables

    * `QBT_EULA` \
      This environment variable defines whether you accept the end-user license agreement (EULA) of qBittorrent. \
      **Put `accept` only if you understand and accepted the EULA.** You can find
      the EULA [here](https://github.com/qbittorrent/qBittorrent/blob/56667e717b82c79433ecb8a5ff6cc2d7b315d773/src/app/main.cpp#L320-L323).
    * `QBT_VERSION` \
      This environment variable specifies the version of qBittorrent-nox to use. \
      For example, `4.4.5-1` is a valid entry. You can find all tagged versions [here](https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox/tags). \
      Or you can put `latest` to use the latest stable release of qBittorrent. \
      If you are up to test the bleeding-edge version, you can put `alpha` to get the weekly build.
    * `QBT_WEBUI_PORT` \
      This environment variable sets the port number which qBittorrent WebUI will be binded to.
      Defaults to port `8080` if value is not set.

    #### Volumes

    There are some paths involved:
    * `<your_path>/config` \
      Full path to a folder on your host machine which will store qBittorrent configurations.
      Using relative path won't work.
    * `<your_path>/downloads` \
      Full path to a folder on your host machine which will store the files downloaded by qBittorrent.
      Using relative path won't work.

3. Running the image

    * If using Docker (not Docker Compose), edit the variables and run:
      ```shell
      export \
        QBT_EULA=<put_accept_here> \
        QBT_VERSION=latest \
        QBT_WEBUI_PORT=8080 \
        QBT_CONFIG_PATH="<your_path>/config" \
        QBT_DOWNLOADS_PATH="<your_path>/downloads"
      docker run \
        -t \
        --name qbittorrent-nox \
        --read-only \
        --rm \
        --stop-timeout 1800 \
        --tmpfs /tmp \
        -e QBT_EULA \
        -e QBT_WEBUI_PORT \
        -p "$QBT_WEBUI_PORT":"$QBT_WEBUI_PORT"/tcp \
        -p 6881:6881/tcp \
        -p 6881:6881/udp \
        -v "$QBT_CONFIG_PATH":/config \
        -v "$QBT_DOWNLOADS_PATH":/downloads \
        qbittorrentofficial/qbittorrent-nox:${QBT_VERSION}
      ```

    * If using Docker Compose:
      ```shell
      docker compose up
      ```

    * A few notes:
      * Alternatively, you can use `ghcr.io/qbittorrent/docker-qbittorrent-nox:${QBT_VERSION}`
        for the image path.
      * By default the timezone in the container uses the default of Alpine Linux (which is most likely `UTC`).
        You can set the environment variable `TZ` to your preferred value.
      * You can change the User ID (UID) and Group ID (GID) of the `qbittorrent-nox` process by setting
        environment variables `PUID` and `PGID` respectively. By default they are both set to `1000`. \
        Note that you will need to remove `--read-only` flag (when using Docker) or set
        `read_only: false` (when using Docker Compose) as they are incompatible with it.
      * You can set additional group ID (AGID) of the `qbittorrent-nox` process by setting the
        environment variable `PAGID`. For example: `10000,10001`, this will set the process to be in
        two (secondary) groups `10000` and `10001`. By default there is no additional group. \
        Note that you will need to remove `--read-only` flag (when using Docker) or set
        `read_only: false` (when using Docker Compose) as they are incompatible with it.
      * It is possible to set the umask of the `qbittorrent-nox` process by setting the
        environment variable `UMASK`. By default it uses the default from Alpine Linux.
      * You can list the compile-time Software Bill of Materials (sbom) with the following command:
        ```shell
        docker run --entrypoint /bin/cat --rm qbittorrentofficial/qbittorrent-nox:latest /sbom.txt
        ```

    * Then you can login to qBittorrent-nox at: `http://<your_docker_host_address>:8080` \
      The default username/password is: `admin/adminadmin`. \
      Don't forget to change the login password to something else! \
      You can change it at 'Tools' menu -> 'Options...' -> 'Web UI' tab -> 'Authentication'

4. Stopping container

    * When using Docker (not Docker Compose):
      ```shell
      docker stop qbittorrent-nox
      ```

    * When using Docker Compose:
      ```shell
      docker compose down
      ```

## Build image manually

Refer to [manual_build](https://github.com/qbittorrent/docker-qbittorrent-nox/tree/main/manual_build) folder.

## Debugging

To attach gdb to the running qbittorent-nox process, follow the steps below:

1. Before you start the container
   * Remove `--read-only` as it will need additional packages within the container. \
     Or disable the respective attributes in docker-compose.yml.
   * Add `--cap-add=SYS_PTRACE` to `docker run` argument list. \
     Or enable the respective attributes in docker-compose.yml.

2. Start the container

3. Drop into container
   ```shell
   # to find container id
   docker ps
   # drop into container
   docker exec -it <container_id> /bin/sh
   ```

4. Install packages
   ```shell
   apk add \
     gdb \
     musl-dbg
   ```

5. Attach gdb to the running process
   ```shell
   # to find PID of qbittorrent-nox
   ps -a
   # attach debugger
   gdb -p <PID>
   ```
