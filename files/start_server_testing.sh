#!/bin/bash
while true; do
  export WINEDLLOVERRIDES="mscoree,mshtml="
  export WINEARCH=win64
  export WINEPREFIX=/home/steam/.wine64
  # Start X virtual framebuffer
  export XDG_RUNTIME_DIR=$(mktemp -d)
  Xvfb :0 -screen 0 1280x1024x16 &
  XVFB_PID=$!
  ## Start VNC server
  echo "Starting VNC server..."
  x11vnc -display :0 -forever -passwd nopass01 -no6 -xkb -rfbport 5900 -quiet &
  VNC_PID=$!
  trap "kill $XVFB_PID $VNC_PID; rm -rf $XDG_RUNTIME_DIR" EXIT
  wine Bin64_dedicated/MiscreatedServer.exe +sv_maxplayers 50 +map islands +http_startserver
  WINE_PID=$!
  while [ ! -f /app/server.log ]; do
    sleep 1
  done
  tail -n100 -f /app/server.log &
  TAIL_PID=$!
  wait $WINE_PID
  kill $TAIL_PID
  sleep 10
done