#!/usr/bin/env bash
RDP_PORT=3389
GAME_PORT=64090
CONTAINER_NAME=miscreated-server
docker run -d --name "${CONTAINER_NAME}" \
    -p ${RDP_PORT}:3389/tcp \
    -p ${GAME_PORT}:64090/udp \
    -p $((GAME_PORT + 1)):64091/udp \
    -p $((GAME_PORT + 2)):64092/udp \
    -p $((GAME_PORT + 3)):64093/udp \
    -p $((GAME_PORT + 4)):64094/tcp \
    miscreated-server