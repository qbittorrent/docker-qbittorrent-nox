# qBittorrent-nox Docker Image [![GitHub Actions CI Status](https://github.com/qbittorrent/docker-qbittorrent-nox/actions/workflows/release.yaml/badge.svg)](https://github.com/qbittorrent/docker-qbittorrent-nox/actions)

Repository on Docker Hub: https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox \
Repository on GitHub: https://github.com/qbittorrent/docker-qbittorrent-nox

## Supported architectures

* linux/386
* linux/amd64
* linux/arm/v6
* linux/arm/v7
* linux/arm64/v8
* linux/riscv64

## Reporting bugs and issues

If the problem is related to the qBittorrent-nox Docker container, please report it to this repository: \
https://github.com/qbittorrent/docker-qbittorrent-nox/issues

If the problem is related to qBittorrent itself, please report it to the main repository: \
https://github.com/qbittorrent/qBittorrent/issues

If you are unsure or want to ask a question, please open a discussion: https://github.com/qbittorrent/docker-qbittorrent-nox/discussions

## Usage

### Prerequisites

In order to run this image you will need Docker installed: https://docs.docker.com/get-docker/

If you don't need the GUI, you can just install Docker Engine: https://docs.docker.com/engine/install/

It is also recommended to install Docker Compose as it can simplify the process significantly: https://docs.docker.com/compose/install/

### Download this repository

Either `git clone` this repository or [download it as a zip archive](https://github.com/qbittorrent/docker-qbittorrent-nox/archive/refs/heads/main.zip).

### Edit the Docker environment file

For Docker compose, open the `.env` file at the root of the repository and set the variables according to the following section.

For Docker Stack, refer to the [docker-stack.yml](https://github.com/qbittorrent/docker-qbittorrent-nox/blob/main/docker-stack.yml) file as an example. \
It is an almost ready-to-use configuration, though a few variables need to be filled in according to the following section.

For the Docker command-line, the environment file does not need to be edited.
They are set in the `docker run ...` command according to the following section.

#### Environment variables

* `QBT_LEGAL_NOTICE` \
  Confirm that you have read [qBittorrent's legal notice](https://github.com/qbittorrent/qBittorrent/blob/56667e717b82c79433ecb8a5ff6cc2d7b315d773/src/app/main.cpp#L320-L323). \
  **Put `confirm` only if you have read the legal notice!**
  
* `QBT_VERSION` \
  The version of qBittorrent-nox to use. \
  It can be a [tagged version](https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox/tags) (*e.g.* `4.4.5-1`), the latest stable version (`latest`) or the bleeding-edge weekly build (`alpha`).
  A `lt2` variation which uses libtorrent v2.0.x is also available. [Users have reported memory and performance issues](https://github.com/arvidn/libtorrent/issues/6667) so use at your own risks!
  
* `QBT_TORRENTING_PORT` \
  The port used for torrenting traffic.
  Defaults to port `6881` if not set.
  
* `QBT_WEBUI_PORT` \
  The port used for qBittorrent Web UI.
  Defaults to port `8080` if not set.

#### Volumes

The following folders need to be defined by their full paths. Using a relative path will not work.
* `QBT_CONFIG_PATH`: qBittorrent configuration folder.
* `QBT_DOWNLOADS_PATH`: qBittorrent default download folder.
      
#### Other settings

* The image value can be changed to `ghcr.io/qbittorrent/docker-qbittorrent-nox:${QBT_VERSION}` to use the GitHub registry which mirrors the same image.

* You can pass additional command-line arguments to `qbittorrent-nox` by appending them to the end of `docker run ...` command, or by adding them in the `command:` array of the [`docker-compose.yml`](https://github.com/qbittorrent/docker-qbittorrent-nox/blob/main/docker-compose.yml) file.

* The container's timezone uses Alpine Linux's default `UTC`. The `TZ` environment variable can be set to another value from the [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

> [!WARNING]
> Docker's default grace period before forcefully shutting down a container is too short for qBittorrent-nox to exit properly.
> This can lead to corrupted files and errors when restarting the container afterwards because of orphaned lock files.
> It is recommended to set `--stop-timeout 1800` or `stop_grace_period: 30m` to override the default 10s and ensure a clean stop.

#### Running as a non-root user

The User ID (UID), Group ID (GID) of the `qbittorrent-nox` process can be changed by two means:

* Creating the container in rootless mode with `--user <uid>:<gid>` or `user: <uid>:<gid>`.
* Setting the `PUID`, `PGID` and `PAGID` environment variables. By default `PUID` and `PGID` are both set to `1000`. An optional additional group ID (AGID) can also be set by using the `PAGID` environment variable. It is empty by default and accepts several additional groups (*e.g.* `10000,10001`). These environment variables are ignored if the container is already running in rootless mode.

> [!NOTE]
> User change is incompatible with the read-only option. You will need to remove the `--read-only` flag or set `read_only: false`.

Setting the `UMASK` will change the umask of the `qbittorrent-nox` process. Its default is the same as Alpine Linux's.

### Running the image

* Docker command-line, edit the variables and run:
  ```shell
  export \
    QBT_LEGAL_NOTICE=<put_confirm_here> \
    QBT_VERSION=latest \
    QBT_TORRENTING_PORT=6881 \
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
    -e QBT_LEGAL_NOTICE \
    -e QBT_TORRENTING_PORT \
    -e QBT_WEBUI_PORT \
    -p "$QBT_TORRENTING_PORT":"$QBT_TORRENTING_PORT"/tcp \
    -p "$QBT_TORRENTING_PORT":"$QBT_TORRENTING_PORT"/udp \
    -p "$QBT_WEBUI_PORT":"$QBT_WEBUI_PORT"/tcp \
    -v "$QBT_CONFIG_PATH":/config \
    -v "$QBT_DOWNLOADS_PATH":/downloads \
    qbittorrentofficial/qbittorrent-nox:${QBT_VERSION}
  ```

* Docker Compose, in the repository folder run:
  ```shell
  docker compose up
  ```

#### Logging into the web UI

When the container is running, you can log into qBittorrent-nox at `http://<your_docker_host_address>:8080` using the username `admin` and the temporary password that qBittorrent-nox generates and prints in the console and the logs via stdout. If you don't have a console attached, run `docker logs qbittorrent-nox` to show the logs.

Older versions ([pre 4.6.1](https://www.qbittorrent.org/news#mon-nov-20th-2023---qbittorrent-v4.6.1-release)) use `adminadmin` as the default password.

> [!NOTE]
> Don't forget to change your admin password after logging in!
> In the Web UI: 'Tools' menu -> 'Options…' -> 'Web UI' tab -> 'Authentication'

4. Stopping the container

* Docker command-line:
  ```shell
  docker stop qbittorrent-nox
  ```

* Docker Compose:
  ```shell
  docker compose down
  ```

## Manually building the image

Refer to [manual_build](https://github.com/qbittorrent/docker-qbittorrent-nox/tree/main/manual_build) folder.

## SBOM

The compile-time Software Bill of Materials (SBOM) is accessible by the following command:
```shell
docker run --entrypoint /bin/cat --rm qbittorrentofficial/qbittorrent-nox:latest /sbom.txt
```

## Debugging

To attach the GNU Debugger (GDB) to qBittorrent-nox, follow these instructions:

1. Before starting the container
   * Remove `--read-only` or set `read_only: false` to allow the installation of additional packages within the container.
   * Add `--cap-add=SYS_PTRACE` or set `cap_add: - SYS_PTRACE`.

2. Start the container

3. Drop into container
   ```shell
   # Find the container ID
   docker ps
   # Open an interactive shell in the container
   docker exec -it <container_id> /bin/sh
   ```

4. Install the debugging packages
   ```shell
   apk add \
     gdb \
     musl-dbg
   ```

5. Attach GDB to the running process
   ```shell
   # Find the PID of qbittorrent-nox
   ps -a
   # Attach the debugger to the process
   gdb -p <PID>
   ```
