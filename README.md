# mikenye/flightradar24

Docker container running FlightRadar24's `fr24feed`. Designed to work in tandem with [mikenye/readsb](https://hub.docker.com/repository/docker/mikenye/readsb) or [mikenye/piaware](https://hub.docker.com/repository/docker/mikenye/piaware). Builds and runs on `x86_64`, `arm32v7` & `arm64` (see below).

`fr24feed` pulls ModeS/BEAST information from the [mikenye/piaware](https://hub.docker.com/repository/docker/mikenye/piaware) (or another host providing ModeS/BEAST data), and sends data to FlightRadar24.

For more information on what fr24feed is, see here: [share-your-data](https://www.flightradar24.com/share-your-data).

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* Version and architecture specific tags available
* `development` (`master` branch, `Dockerfile`, `amd64` architecture only, not recommended for production)

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `linux/amd64`: Linux x86-64
* `linux/arm/v7`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3)
* `linux/arm64/v8`: ARMv8 64-bit

A note on `arm64`: FlightRadar24 only make binaries available for `amd64` and `armhf`. The `arm64` version of this container uses the `armhf` binaries which are compiled for `arm32`. `arm32` support is optional on `arm64`. In practice, there is only one `arm64` CPU that omits legacy `arm32` instruction set support - Cavium ThunderX. Thus, this image should work on any `arm64` system that doesn't have the Cavium ThunderX CPU. [Reference](https://askubuntu.com/questions/928249/how-to-run-armhf-executables-on-an-arm64-system).

## Obtaining a Flightradar24 Sharing Key

First-time users should obtain a Flightradar24 sharing key.

In order to obtain a Flightradar24 sharing key, initially run the container with the following command:

```shell
docker run --rm -it --entrypoint fr24feed mikenye/fr24feed --signup
```

This will take you through the signup process. At the end of the signup process, you'll be presented with:

```
Congratulations! You are now registered and ready to share ADS-B data with Flightradar24.
+ Your sharing key (xxxxxxxxxxxx) has been configured and emailed to you for backup purposes.
+ Your radar id is X-XXXXXXX, please include it in all email communication with us.
```

Take a note of the sharing key, as you'll need it when launching the container.

## Configuring `mikenye/piaware` Container

If you're using this container with the `mikenye/piaware` container to provide ModeS/BEAST data, you'll need to ensure you've opened port 30005 into the `mikenye/piaware` container, so this container can connect to it.

The IP address or hostname of the docker host running the `mikenye/piaware` container should be passed to the `mikenye/fr24feed` container via the `BEASTHOST` environment variable shown below. The port can be changed from the default of 30005 with the optional `BEASTPORT` environment variable.

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name fr24feed \
 -e TZ="YOUR_TIMEZONE" \
 -e BEASTHOST=beasthost \
 -e MLAT=yes \
 -e FR24KEY=xxxxxxxxxxx \
 -p 8754:8754 \
 mikenye/fr24feed
```

## Up-and-Running with Docker Compose

```shell
version: '2.0'

services:
  fr24feed:
    image: mikenye/fr24feed:latest
    tty: true
    container_name: fr24feed
    restart: always
    ports:
      - 8754:8754
    environment:
      - TZ="Australia/Perth"
      - BEASTHOST=beasthost
      - MLAT=yes
      - FR24KEY=xxxxxxxxxxx
```

## Up-and-Running with Docker Compose, including `mikenye/piaware`

```shell
version: '2.0'

services:

  piaware:
    image: mikenye/piaware:latest
    tty: true
    container_name: piaware
    mac_address: de:ad:be:ef:13:37
    restart: always
    devices:
      - /dev/bus/usb/001/004:/dev/bus/usb/001/004
    ports:
      - 8080:8080
      - 30005:30005
    environment:
      - TZ="Australia/Perth"
      - LAT=-32.463873
      - LONG=113.458482
    volumes:
      - /var/cache/piaware:/var/cache/piaware

  fr24feed:
    image: mikenye/fr24feed:latest
    tty: true
    container_name: fr24feed
    restart: always
    ports:
      - 8754:8754
    environment:
      - BEASTHOST=piaware
      - FR24KEY=xxxxxxxxxxx
      - MLAT=yes
```

For an explanation of the `mikenye/piaware` image's configuration, see that image's readme.

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090) | |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090) | 30005 |
| `FR24KEY`            | Required. Flightradar24 Sharing Key | |
| `TZ`                 | Your local timezone (optional)  | GMT     |
| `MLAT`               | Enable multilateration (optional) | no |
| `VERBOSE_LOGGING`    | Set to `true` to enable verbose logging (optional) | `false` |

## Ports

The following ports are used by this container:

* `8754` - fr24feed web interface - optional but recommended
* `30003` - fr24feed TCP BaseStation output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30334` - fr24feed TCP Raw output listen port - optional, recommended to leave unmapped unless explicitly needed

## Logging

* The `fr24feed` process is logged to the container's stdout, and can be viewed with `docker logs [-f] container`.
* `fr24feed` log file exists at `/var/log/fr24feed.log`, with automatic log rotation.

## Getting Help

Having troubles with the container or have questions?  Please [create a new issue](https://github.com/mikenye/docker-flightradar24/issues).

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
