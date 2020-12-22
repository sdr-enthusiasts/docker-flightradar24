# mikenye/flightradar24

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-flightradar24/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-flightradar24/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/fr24feed.svg)](https://hub.docker.com/r/mikenye/fr24feed)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/fr24feed/latest)](https://hub.docker.com/r/mikenye/fr24feed)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running FlightRadar24's `fr24feed`. Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf). Builds and runs on `x86_64`, `arm32v7`, `arm64` and `386`.

`fr24feed` pulls ModeS/BEAST information from the [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf) (or another host providing ModeS/BEAST data), and sends data to FlightRadar24.

For more information on what fr24feed is, see here: [share-your-data](https://www.flightradar24.com/share-your-data).

## NOTICE

RPi users are reporting issues with the latest versions (`1.0.26-4` and above) of the `fr24feed` binary from FR24. RPi users are encouraged to remain on version `1.0.25-3` until these issues are resolved. I've temporarily reverted the `latest` images to `1.0.25-3` until this is resolved. See <https://github.com/mikenye/docker-flightradar24/issues/14> for further details.

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
* Version and architecture specific tags available

## Multi Architecture Support

A note on `arm64`: FlightRadar24 only make binaries available for `amd64`, `386` and `armhf`. The `arm64` version of this container uses the `armhf` binaries which are compiled for `arm32`. `arm32` support is optional on `arm64`. In practice, there is only one `arm64` CPU that omits legacy `arm32` instruction set support - Cavium ThunderX. Thus, this image should work on any `arm64` system that doesn't have the Cavium ThunderX CPU. [Reference](https://askubuntu.com/questions/928249/how-to-run-armhf-executables-on-an-arm64-system).

## Obtaining a Flightradar24 Sharing Key

First-time users should obtain a Flightradar24 sharing key.

In order to obtain a Flightradar24 sharing key, initially run the container as-per one of the methods below.

### Script Method

Run the following command to temporarily start the container and complete the automated signup process:

```shell
docker run \
  --rm \
  -it \
  -e FEEDER_LAT="YOUR_FEEDER_LAT" \
  -e FEEDER_LONG="YOUR_FEEDER_LONG" \
  -e FEEDER_ALT_FT="YOUR_FEEDER_ALT_FT" \
  -e FR24_EMAIL="YOUR@EMAIL.ADDRESS" \
  --entrypoint /scripts/signup.sh \
  mikenye/fr24feed 
```

Remember to replace:

* `YOUR_FEEDER_LAT` with the latitude of your feeder's antenna
* `YOUR_FEEDER_LONG` with the longitude of your feeder's antenna
* `YOUR_FEEDER_ALT_FT` with the altitude of your feeder's antenna above sea level **in feet**
* `YOUR@EMAIL.ADDRESS` with your email address.

After 30 seconds or so, you should see the following output:

```
FR24_SHARING_KEY=5fa9ca2g9049b615
FR24_RADAR_ID=T-XXXX123
```

Take a note of the sharing key, as you'll need it when launching the container. 

### Manual Method

If the script method fails (please let me know so I can fix it), you can sign up manually.

Temporarily run the container with the following command:

```shell
docker run --rm -it --entrypoint fr24feed mikenye/fr24feed --signup
```

This will take you through the signup process. Most of the answers don't matter as during normal operation the configuration will be set with environment variables. I would suggest answering as follows:

* `Step 1.1 - Enter your email address (username@domain.tld)`: Enter your email address.
* `Step 1.2 - If you used to feed FR24 with ADS-B data before, enter your sharing key.`: Leave blank and press enter.
* `Step 1.3 - Would you like to participate in MLAT calculations?`: Answer `yes`.
* `Step 3.A - Enter antenna's latitude (DD.DDDD)`: Enter your antenna's latitude.
* `Step 3.B - Enter antenna's longitude (DDD.DDDD)`: Enter your antenna's longitude.
* `Step 3.C - Enter antenna's altitude above the sea level (in feet)`: Enter your antenna's altitude above sea level **in feet**.
* `Would you like to continue using these settings?`: Answer `yes`.
* `Step 4.1 - Receiver selection (in order to run MLAT please use DVB-T stick with dump1090 utility bundled with fr24feed)... Enter your receiver type (1-7)`: Answer `7`.
* `Step 6 - Please select desired logfile mode... Select logfile mode (0-2)`: Answer `0`.

At the end of the signup process, you'll be presented with:

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
