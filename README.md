# sdr-enthusiasts/docker-flightradar24

![Build Passing](https://img.shields.io/github/actions/workflow/status/sdr-enthusiasts/docker-flightradar24/deploy.yml?branch=main)
![Contributors](https://img.shields.io/github/contributors/sdr-enthusiasts/docker-flightradar24)
![Last Commit](https://img.shields.io/github/last-commit/sdr-enthusiasts/docker-planefence)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running FlightRadar24's `fr24feed`. Designed to work in tandem with [ultrafeeder](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder) or any other BEAST formal data source. Builds and runs on `x86_64`, `armhf` & `arm64`.

`docker-flightradar24` pulls ModeS/BEAST information from the [ultrafeeder container](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder) (or another host providing ModeS/BEAST data), and sends data to FlightRadar24.

For more information on what fr24feed is, see here: [share-your-data](https://www.flightradar24.com/share-your-data).

- [sdr-enthusiasts/docker-flightradar24](#sdr-enthusiastsdocker-flightradar24)
  - [Supported tags and respective Dockerfiles](#supported-tags-and-respective-dockerfiles)
  - [Obtaining a Flightradar24 Sharing Key for ADSB](#obtaining-a-flightradar24-sharing-key-for-adsb)
  - [Up-and-Running with `docker run`](#up-and-running-with-docker-run)
  - [Up-and-Running with Docker Compose](#up-and-running-with-docker-compose)
  - [Runtime Environment Variables](#runtime-environment-variables)
  - [Ports](#ports)
  - [UAT configuration (USA only)](#uat-configuration-usa-only)
  - [Logging](#logging)
  - [Troubleshooting](#troubleshooting)
  - [Getting Help](#getting-help)

## Supported tags and respective Dockerfiles

- `latest` (`main` branch, `Dockerfile`)
- `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
- Version and architecture specific tags available

## Obtaining a Flightradar24 Sharing Key for ADSB

First-time users should obtain a Flightradar24 sharing key.

If you don't already have a FlightRadar24 account, then first go to the [FlightRadar24](https://flightradar24.com) website and create an account. Remember the email address you used; you will be asked for it later.
Then copy and paste the following command on your target machine (or really any armhf/arm64/x86_64 linux machine with Docker installed):

```bash
docker run -it --rm ghcr.io/sdr-enthusiasts/docker-baseimage:qemu bash -c "$(curl -sSL https://raw.githubusercontent.com/sdr-enthusiasts/docker-flightradar24/main/get_adsb_key.sh)"
```

This will start up a container. After installing a bunch of software (which may take a while depending on the speed of your machine and internet connection), it will take you through the signup process. Most of the answers don't matter as during normal operation the configuration will be set with environment variables. I would suggest answering as follows:

- `Step 1.1 - Enter your email address (username@domain.tld)`: Enter your FlightRadar24 account email address
- `Step 1.2 - If you used to feed FR24 with ADS-B data before, enter your sharing key.`: Leave blank and press enter
- `Step 1.3 - Would you like to participate in MLAT calculations?`: Answer `no`
- `Would you like to continue using these settings?`: Answer `yes`
- `Step 4.1 - Receiver selection (in order to run MLAT please use DVB-T stick with dump1090 utility bundled with fr24feed)... Enter your receiver type (1-7)`: Answer `4`.
- `Enter your connection type`: Answer `1`.
- `host`: Answer: 127.0.0.1
- `port`: Answer: 30005
- `Step 5`: Answer: 2x `no`

Note that there is a limit of 3 feeders per FR24 account. ADSB and UAT (see below) both count as 1 feeder. If you have more than 3 feeders, you will need to contact <support@fr24.com> to request an additional Feeder Key. Make sure to send them your account email-address, latitude, longitude, altitude, and if the key is for an ADSB or UAT feeder.

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name fr24feed \
 -e BEASTHOST=beasthost \
 -e FR24KEY=xxxxxxxxxxx \
 -p 8754:8754 \
 ghcr.io/sdr-enthusiasts/docker-flightradar24:latest
```

## Up-and-Running with Docker Compose

```shell
version: '2.0'

services:
  fr24feed:
    image: ghcr.io/sdr-enthusiasts/docker-flightradar24:latest
    tty: true
    container_name: fr24feed
    restart: always
    ports:
      - 8754:8754
    environment:
      - BEASTHOST=beasthost
      - FR24KEY=xxxxxxxxxxx
```

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                                                                                        | Default  |
| -------------------- | ---------------------------------------------------------------------------------------------- | -------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090)                                    | `readsb` |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090)                                  | `30005`  |
| `FR24KEY`            | Required. Flightradar24 Sharing Key                                                            |          |
| `MLAT`               | Set to `yes` to enable MLAT (optional)                                                         | `no`     |
| `BIND_INTERFACE`     | Optional. Set a bind interface such as `0.0.0.0` to allow access from non-private IP addresses | _none_   |
| `VERBOSE_LOGGING`    | Set to `true` to enable verbose logging (optional)                                             | `false`  |
| `FR24KEY_UAT`        | Optional. Only used if you are feeding UAT data - see section below                            | _empty_  |
| `UATHOST`            | Optional. Only used if you are feeding UAT data and you don't use the default value                             | `dump978`  |
| `UATPORT`            | Optional. Only used if you are feeding UAT data and you don't use the default value                             | `30978`    |

## Ports

The following ports are used by this container:

- `8754` - fr24feed (adsb) web interface - optional but recommended
- `8755` - fr24feed-uat web interface - optional, only interesting if you are feeding UAT data
- `30003` - fr24feed TCP BaseStation output listen port - optional, recommended to leave unmapped unless explicitly needed
- `30334` - fr24feed TCP Raw output listen port - optional, recommended to leave unmapped unless explicitly needed

## UAT configuration (USA only)

UAT is a second channel (978 MHz) on which ADSB data is transmitted by some aircraft that only fly at lower altitudes. It is only used in the US. **If you are not in the US (or on its borders), then you can safely skip this section.**

If you have a UAT receiver with an existing `dump978` container or `dump978-fa` deployment, you can add this to your feed following the steps below. Note - if you don't already have a UAT receiver deployed, you should first read and implement [this container](https://github.com/sdr-enthusiasts/docker-dump978) before going any further. We only support UAT deployments with a separate `dump978` container or a separately installed `dump978-fa` instance.

1. Signup for a UAT sharing key. Note - you CANNOT reuse your existing ADSB sharing key. To do so, copy and paste the following command on your target machine (or really any armhf/arm64/x86_64 linux machine with Docker installed):

```bash
docker run -it --rm ghcr.io/sdr-enthusiasts/docker-baseimage:qemu bash -c "$(curl -sSL https://raw.githubusercontent.com/sdr-enthusiasts/docker-flightradar24/main/get_uat_key.sh)"
```

- Step 1.1: Enter the email address associated with your existing (ADSB) FlightRadar24 account.
- Step 1.2: Leave this BLANK - you will get assigned a new key. You cannot reuse your existing ADSB `FR24KEY`.
- Steps 3.A/3.B/3.C: enter your latitude/longitude/height (ft)
- Step 4.1: Enter `2` (DVBT Stick (DUMP978-FA RAW TCP))
- Step 4.2: You can leave the default value of `30978`
- Now you see a text like this:

```text
Congratulations! You are now registered and ready to share UAT data with Flightradar24.
+ Your sharing key (fxxxxxxxxxxx4) has been configured and emailed to you for backup purposes.
+ Your radar id is T-XXXX120, please include it in all email communication with us.
+ Please make sure to start sharing data within one month from now as otherwise your ID/KEY will be deleted.
```

- Make note of your Sharing Key value (`fxxxxxxxxxxx4` in the example above) and add it to the `FR24KEY_UAT` variable
- If your UAT receiver is not the `dump978` container and port `30978`, you can set those as optionally as well:

```yaml
  - FR24KEY_UAT=fxxxxxxxxxxx4
  - UATHOST=hostname
  - UATPORT=12345
```

Note that there is a limit of 3 feeders per FR24 account. ADSB and UAT each count as 1 feeder. If you have more than 3 feeders, you will need to contact <support@fr24.com> to request an additional Feeder Key. Make sure to send them your account email-address, latitude, longitude, altitude, and if the key is for an ADSB or UAT feeder.

Restart the container. After a few minutes, you can see on [https://www.flightradar24.com/account/data-sharing](https://www.flightradar24.com/account/data-sharing) that data is received.

## Logging

- The `fr24feed` process is logged to the container's stdout, and can be viewed with `docker logs [-f] container`.
- `fr24feed` log file exists at `/var/log/fr24feed.log`, with automatic log rotation.

## Troubleshooting

- This error is shown in the Container Logs: `[WARNING] Cannot check data flow because tcpdump fails to execute. Try adding NET_ADMIN and NET_RAW capabilities to your container`. Solutions:
  - Add `NET_ADMIN` and `NET_RAW` capabilities to your container service definition. If you can't do this:
  - set `WATCH_INTERVAL=infinity` in your container environment variables

## Getting Help

Having troubles with the container or have questions? Best support is available on the #adsb-containers channel of the [SDR-Enthusiasts Discord seerver](https://discord.gg/sTf9uYF). Feel free to [join](https://discord.gg/sTf9uYF) and converse.

Alternatively, you can [create a new issue](https://github.com/sdr-enthusiasts/docker-flightradar24/issues) but sometimes it takes a while for us to notice and respond. Support on Discord is much faster!
