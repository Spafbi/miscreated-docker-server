#!/bin/bash
: ${MAP:=islands}
: ${PLAYERS:=36}
: ${SERVER_ID:=100}
: ${WHITELISTED:=0}
WHITELIST_BLOCK=""
if [[ "${WHITELISTED,,}" =~ ^(1|y|t|true)$ ]]; then
    WHITELIST_BLOCK="-mis_whitelist"
fi
XAUTH=$(mktemp)
XDUMP=~/.miscreated-xdump
export WINEPREFIX="/app/.wine"
export WINEDLLOVERRIDES="mscoree,mshtml="
umask=002
# Start the server
while true; do
WINEDEBUG=-fixme-all xvfb-run -e ${XDUMP} -f ${XAUTH} -a /usr/bin/wine /app/Bin64_dedicated/MiscreatedServer.exe -mis_gameserverid ${SERVER_ID} +sv_maxplayers ${PLAYERS} +map ${MAP} +http_startserver ${WHITELIST_BLOCK}
done