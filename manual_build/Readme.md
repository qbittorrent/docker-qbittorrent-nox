# Manually Build the qBittorrent-nox Docker Image

This Dockerfile allows you to build a Docker image containing qBittorrent-nox.

## Prerequisites

In order to build or run this image, you will need Docker installed: <https://docs.docker.com/get-docker/>

If you don't need the GUI, you can just install Docker Engine: <https://docs.docker.com/engine/install/>

It is also recommended to install Docker Compose as it can simplify the process significantly: <https://docs.docker.com/compose/install/>

## Building the Docker Image

* If you are using Docker (not Docker Compose), run the following commands in this folder:

  ```shell
  export \
    QBT_VERSION=devel
  docker build \
    --build-arg QBT_VERSION \
    -t qbittorrent-nox:"$QBT_VERSION" \
    .
  ```

* If you are using Docker Compose, you should edit the `.env` file first.
  You can find an explanation of the variables in the following [Parameters](#parameters) section. \
  Then run the following commands in this folder:

  ```shell
  docker compose build \
    --build-arg QBT_VERSION
  ```

### Parameters

#### Environment variables

* `QBT_LEGAL_NOTICE` \
  Confirm that you have read [qBittorrent's legal notice](https://github.com/qbittorrent/qBittorrent/blob/56667e717b82c79433ecb8a5ff6cc2d7b315d773/src/app/main.cpp#L320-L323). \
  **Put `confirm` only if you have read the legal notice.**
* `QBT_VERSION` \
  The version of qBittorrent-nox to use. \
  It can be `devel` to build the latest development version or a [tagged version](https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox/tags): `4.4.5-1`.
* `QBT_TORRENTING_PORT` \
  The port number for torrenting traffic. \
  Defaults to port `6881` if value is not set.
* `QBT_WEBUI_PORT` \
  The port number for qBittorrent WebUI. \
  Defaults to port `8080` if value is not set.

#### Volumes

* `<your_path>/config` \
  Full path to a folder on your host machine which will store qBittorrent configurations.
  Using a relative path will not work.
* `<your_path>/downloads` \
  Full path to a folder on your host machine which will store the files downloaded by qBittorrent.
  Using a relative path will not work.

## Running the container

* Using Docker (not Docker Compose), simply run:

  ```shell
  export \
    QBT_LEGAL_NOTICE=<put_confirm_here> \
    QBT_VERSION=devel \
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
    -e TZ=UTC \
    -p "$QBT_TORRENTING_PORT":"$QBT_TORRENTING_PORT"/tcp \
    -p "$QBT_TORRENTING_PORT":"$QBT_TORRENTING_PORT"/udp \
    -p "$QBT_WEBUI_PORT":"$QBT_WEBUI_PORT"/tcp \
    -v "$QBT_CONFIG_PATH":/config \
    -v "$QBT_DOWNLOADS_PATH":/downloads \
    qbittorrent-nox:"$QBT_VERSION"
  ```

* Using Docker Compose:

  ```shell
  docker compose up
  ```

### Tweaking the options

* To pass additional command-line arguments to `qbittorrent-nox`, append them to the end of the `docker run ...` command.
  If using Docker Compose, modify the `command:` array in [docker-compose.yml][docker-compose-yml-link].
* ⚠️ To ensure qBittorrent has enough time to shut down properly, you must override the container's stop timeout. \
  If unspecified, the default value is only 10 seconds, which is too short and can interrupt the shutdown procedure,
  leading to corrupted files. \
  Set `--stop-timeout 1800` (or `stop_grace_period: 30m` when using Docker Compose).
* To change the timezone in the container, set the `TZ` environment variable to your preferred value. \
  The default is inherited from Alpine Linux, which is most likely `UTC`.
* To change the User ID (UID) and Group ID (GID) of the `qbittorrent-nox` process, set the
  environment variables `PUID` and `PGID` respectively. \
  The default is `1000` for both.
  * 📢 You will need to remove the `--read-only` flag (when using Docker) or set
    `read_only: false` (when using Docker Compose), as these settings are incompatible.
  * These environment variables have no effect when running the image in rootless mode.
* To set additional group IDs (AGID) for the `qbittorrent-nox` process, set the
  environment variable `PAGID`. For example: `10000,10001`. This will set the process to be in
  two (secondary) groups, `10000` and `10001`. \
  By default, there are no additional groups.
  * 📢 You will need to remove the `--read-only` flag (when using Docker) or set
    `read_only: false` (when using Docker Compose), as these settings are incompatible.
  * This environment variable has no effect when running the image in rootless mode.
* To set the umask of the `qbittorrent-nox` process, set the environment variable `UMASK`. \
  The default is inherited from Alpine Linux.
* To list the compile-time Software Bill of Materials (SBOM), run:

  ```shell
  docker run --entrypoint /bin/cat --rm qbittorrentofficial/qbittorrent-nox:latest /sbom.txt
  ```

### Log in to qBittorrent-nox at: `http://<your_docker_host_address>:8080`

* For newer qBittorrent versions (≥ 4.6.1), qBittorrent will generate a temporary password and print it to the console (via stdout).
  You will need to use this password to log in. See the [announcement](https://www.qbittorrent.org/news#mon-nov-20th-2023---qbittorrent-v4.6.1-release). \
  If you don't have a console attached, you can run the following to view the logs:

  ```shell
  docker logs qbittorrent-nox
  ```

* For older qBittorrent versions (< 4.6.1), the default username/password is: `admin/adminadmin`.

> [!IMPORTANT]
> Don't forget to change your password after logging in! \
> To change it in WebUI: `Tools` menu -> `Options...` -> `WebUI` tab -> `Authentication`

## Stopping the container

* Using Docker (not Docker Compose):

  ```shell
  docker stop qbittorrent-nox
  ```

* Using Docker Compose:

  ```shell
  docker compose down
  ```

[docker-compose-yml-link]: https://github.com/qbittorrent/docker-qbittorrent-nox/blob/main/manual_build/docker-compose.yml
