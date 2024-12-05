#!/bin/bash

# Update the game server if UPDATE_GAME_SERVER environment variable exists
if [ -n "$UPDATE_GAME_SERVER" ]; then
    /steamcmd/steamcmd.sh +force_install_dir /app +login anonymous +app_update 443030 validate +quit
fi

THIS_MAP=islands
THIS_MAXPLAYERS=50
THIS_PORT=64090

if [ -n "$MAP" ]; then
  THIS_MAP=${MAP}
fi

if [ -n "$MAX_PLAYERS" ]; then
  THIS_MAXPLAYERS=${MAX_PLAYERS}
fi

if [ -n "$WHITELISTED" ]; then
  THIS_WHITELISTED="-mis_whitelist"
fi

if [ -n "$BASE_PORT" ]; then
  THIS_PORT=$BASE_PORT
fi

if [ "$GRANTGUIDES" == 1 ] && [ -f /app/miscreated.db ]; then
  echo "Granting crafting guides to all players..."
  sqlite3 /app/miscreated.db <<EOF
  DROP TRIGGER IF EXISTS grant_all_guides;
  CREATE TRIGGER IF NOT EXISTS grant_all_guides AFTER UPDATE ON Characters BEGIN UPDATE ServerAccountData SET Guide00="-1", Guide01="-1"; END;
  UPDATE ServerAccountData SET Guide00="-1", Guide01="-1";
EOF
fi

# Start X virtual framebuffer
Xvfb :0 -screen 0 1024x768x16 &

# Wait to ensure Xvfb is up
sleep 5

# Run the server
while [ ! -f /data/stop ]; do
  cd /app
  wine Bin64_dedicated/MiscreatedServer.exe -sv_port ${THIS_PORT} +sv_maxplayers ${THIS_MAXPLAYERS} +map ${THIS_MAP} +http_startserver ${THIS_WHITELISTED} &
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