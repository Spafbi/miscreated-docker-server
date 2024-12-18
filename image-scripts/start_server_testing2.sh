#!/bin/bash
set -x
while true; do
  export WINEDLLOVERRIDES="mscoree,mshtml="
  export WINEARCH=win64
  export WINEPREFIX=/home/steam/.wine64
  export XDG_RUNTIME_DIR=$(mktemp -d)
  export DISPLAY=:0
  export XAUTHORITY=/home/steam/.Xauthority
  # Start X virtual framebuffer
  # /usr/bin/xvfb-run --server-args="-screen 0 1280x1024x24" /usr/bin/x11vnc -forever -passwd nopass01 -create
  Xvfb :0 -screen 0 1280x1024x24 &
  XVFB_PID=$!
  # Wait to ensure Xvfb is up
  sleep 5
  # Start XRDP
  /etc/init.d/xrdp start
  XRDP_PID=$!
  # /etc/init.d/xrdp start
  # XRDP_PID=$!
  wine Bin64_dedicated/MiscreatedServer.exe +sv_maxplayers 50 +map islands +http_startserver
  WINE_PID=$!
  while [ ! -f /app/server.log ]; do
    sleep 1
  done
  tail -n1000 -f /app/server.log &
  TAIL_PID=$!
  wait $WINE_PID
  # kill $TAIL_PID $XRDP_PID
  kill $TAIL_PID $XVFB_PID $XRDP_PID
  # Clean up the temporary directory
  rm -rf $XDG_RUNTIME_DIR
  sleep 10
done
set +x