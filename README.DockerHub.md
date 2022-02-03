# mikenye/flightradar24

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-flightradar24/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-flightradar24/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/fr24feed.svg)](https://hub.docker.com/r/mikenye/fr24feed)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/fr24feed/latest)](https://hub.docker.com/r/mikenye/fr24feed)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running FlightRadar24's `fr24feed`. Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf). Builds and runs on `x86_64`, `arm32v6`, `arm32v7` & `arm64`.

`fr24feed` pulls ModeS/BEAST information from the [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf) (or another host providing ModeS/BEAST data), and sends data to FlightRadar24.

For more information on what fr24feed is, see here: [share-your-data](https://www.flightradar24.com/share-your-data).

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/mikenye/docker-flightradar24/blob/master/README.md)