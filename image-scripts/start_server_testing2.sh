#!/bin/bash
set -x
while true; do
  export WINEDLLOVERRIDES="mscoree,mshtml="
  export WINEARCH=win64
  export WINEPREFIX=/home/steam/.wine64
  export XDG_RUNTIME_DIR=$(mktemp -d)
  export XAUTHORITY=/home/steam/.Xauthority
  export RDP_PASSWORD=${RDP_PASSWORD:-nopass01}
  # export RDP_USERNAME=${RDP_USERNAME:-steam}

  # Set XRDP credentials
  TEMP_FILE=$(mktemp)
  sed "s/password=ask/password=${RDP_PASSWORD}/" /etc/xrdp/xrdp.ini > $TEMP_FILE
  mv $TEMP_FILE /etc/xrdp/xrdp.ini
  rm -f $TEMP_FILE
  # TEMP_FILE=$(mktemp)
  # sed "s/username=ask/username=${RDP_USERNAME}/" /etc/xrdp/xrdp.ini > $TEMP_FILE
  # mv $TEMP_FILE /etc/xrdp/xrdp.ini
  # rm -f $TEMP_FILE
  # Start X virtual framebuffer
  # /usr/bin/xvfb-run --server-args="-screen 0 1280x1024x24" /usr/bin/x11vnc -forever -passwd nopass01 -create
  Xvfb :0 -screen 0 1280x1024x24 &
  XVFB_PID=$!
  # Wait to ensure Xvfb is up
  sleep 5
  # Start XRDP
  sudo /etc/init.d/xrdp start
  XRDP_PID=$(pgrep -f xrdp)
  # /etc/init.d/xrdp start
  # XRDP_PID=$!
  export DISPLAY=:0
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