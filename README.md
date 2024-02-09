# sdr-enthusiasts/docker-flightradar24

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/fr24feed/latest)](https://hub.docker.com/r/mikenye/fr24feed)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running FlightRadar24's `fr24feed`. Designed to work in tandem with [sdr-enthusiasts/docker-readsb-protobuf](https://github.com/sdr-enthusiasts/docker-readsb-protobuf). Builds and runs on `x86_64`, `arm32v6`, `arm32v7` & `arm64`.

`fr24feed` pulls ModeS/BEAST information from the [sdr-enthusiasts/docker-readsb-protobuf](https://github.com/sdr-enthusiasts/docker-readsb-protobuf) (or another host providing ModeS/BEAST data), and sends data to FlightRadar24.

For more information on what fr24feed is, see here: [share-your-data](https://www.flightradar24.com/share-your-data).

## Supported tags and respective Dockerfiles

- `latest` (`main` branch, `Dockerfile`)
- `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
- Version and architecture specific tags available

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
  -e FR24_SIGNUP=1 \
  ghcr.io/sdr-enthusiasts/docker-flightradar24:latest
```

Remember to replace:

- `YOUR_FEEDER_LAT` with the latitude of your feeder's antenna
- `YOUR_FEEDER_LONG` with the longitude of your feeder's antenna
- `YOUR_FEEDER_ALT_FT` with the altitude of your feeder's antenna above sea level **in feet**
- `YOUR@EMAIL.ADDRESS` with your email address.

After 30 seconds or so, you should see the following output:

```text
FR24_SHARING_KEY=5fa9ca2g9049b615
FR24_RADAR_ID=T-XXXX123
```

Take a note of the sharing key, as you'll need it when launching the container.

### Manual Method

### THIS APPEARS TO BE BROKEN FOR NOW

If the script method fails (please let me know so I can fix it), you can sign up manually.

Temporarily run the container with the following command:

**For ARM platforms:**

```shell
docker run --rm -it --entrypoint /usr/local/bin/fr24feed ghcr.io/sdr-enthusiasts/docker-flightradar24:latest --signup
```

**For other platforms:**

```shell
docker run --rm -it --entrypoint qemu-arm-static ghcr.io/sdr-enthusiasts/docker-flightradar24:latest /usr/local/bin/fr24feed --signup
```

This will take you through the signup process. Most of the answers don't matter as during normal operation the configuration will be set with environment variables. I would suggest answering as follows:

- `Step 1.1 - Enter your email address (username@domain.tld)`: Enter your email address.
- `Step 1.2 - If you used to feed FR24 with ADS-B data before, enter your sharing key.`: Leave blank and press enter.
- `Step 1.3 - Would you like to participate in MLAT calculations?`: Answer `no`.
- `Would you like to continue using these settings?`: Answer `yes`.
- `Step 4.1 - Receiver selection (in order to run MLAT please use DVB-T stick with dump1090 utility bundled with fr24feed)... Enter your receiver type (1-7)`: Answer `7`.
- `Step 6 - Please select desired logfile mode... Select logfile mode (0-2)`: Answer `0`.

At the end of the signup process, you'll be presented with:

```text
Congratulations! You are now registered and ready to share ADS-B data with Flightradar24.
+ Your sharing key (xxxxxxxxxxxx) has been configured and emailed to you for backup purposes.
+ Your radar id is X-XXXXXXX, please include it in all email communication with us.
```

Take a note of the sharing key, as you'll need it when launching the container.

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

UAT is a second frequency on which ADSB data is available. It is only used in the US.
If you have a UAT deployment with an existing `dump978` container, you can add this to your feed like this:

1. Signup for a UAT sharing key. Note - you CANNOT reuse your existing ADSB sharing key. Run the following script and follow the questions

```bash
docker run --rm -it --entry-point /scripts/signup-uat.sh ghrc.io/sdr-enthusiasts/docker-flightradar24 ```
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

1. Make note of your Sharing Key value (`fxxxxxxxxxxx4` in the example above) and add it to the `FR24KEY_UAT` variable
2. If your UAT receiver is not the `dump978` container and port `30978`, you can set those as optionally as well:

```yaml
  - FR24KEY_UAT=fxxxxxxxxxxx4
  - UATHOST=hostname
  - UATPORT=12345
```

Restart the container. After a few minutes, you can see on [https://www.flightradar24.com/account/data-sharing](https://www.flightradar24.com/account/data-sharing) that data is received.

## Logging

- The `fr24feed` process is logged to the container's stdout, and can be viewed with `docker logs [-f] container`.
- `fr24feed` log file exists at `/var/log/fr24feed.log`, with automatic log rotation.

## Getting Help

Having troubles with the container or have questions? Please [create a new issue](https://github.com/sdr-enthusiasts/docker-flightradar24/issues).

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
