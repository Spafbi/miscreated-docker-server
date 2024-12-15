#!/bin/bash
# Function to check if a value is a boolean true equivalent
function bool_check {
  local value=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  if [[ "$value" == "1" || "$value" == "y" || "$value" == "yes" || "$value" == "true" ]]; then
    echo 1
  else
    echo 0
  fi
}

# Function to calculate the distance between two points (not currently used)
function calc_distance {
  local x1=$1
  local y1=$2
  local x2=$3
  local y2=$4
  local dist=$(echo "sqrt(($x2 - $x1)^2 + ($y2 - $y1)^2)" | bc -l)
  echo $dist
}

# Disables debug logging for the server.
# This function restores the original log verbosity levels.
function disable_debug_logging {
  local saved_log_Verbosity=$(get_config_value "saved_log_Verbosity")
  local saved_log_WriteToFileVerbosity=$(get_config_value "saved_log_WriteToFileVerbosity")
  if [ "$saved_log_Verbosity" == "__unset__" ]; then
    remove_config_value "log_Verbosity"
  else
    set_config_value "log_Verbosity" "$saved_log_Verbosity"
  fi
  if [ "$saved_log_WriteToFileVerbosity" == "__unset__" ]; then
    remove_config_value "log_WriteToFileVerbosity"
  else
    set_config_value "log_WriteToFileVerbosity" "$saved_log_WriteToFileVerbosity"
  fi
  remove_config_value "saved_log_Verbosity"
  remove_config_value "saved_log_WriteToFileVerbosity"
}

# Enables debug logging for the server.
# This function configures the necessary settings to turn on detailed logging,
# which can be useful for troubleshooting and monitoring server behavior.
function enable_debug_logging {
  local log_Verbosity=$(get_config_value "log_Verbosity")
  local log_WriteToFileVerbosity=$(get_config_value "log_WriteToFileVerbosity")
  if [ -z "$(get_config_value "saved_log_Verbosity")" ]; then
    if [ -n "$log_Verbosity" ]; then
      set_config_value "saved_log_Verbosity" "$log_Verbosity"
    else
      set_config_value "saved_log_Verbosity" "__unset__"
    fi
  fi
  set_config_value "log_Verbosity" 3
  if [ -z "$(get_config_value "saved_log_WriteToFileVerbosity")" ]; then
    if [ -n "$log_WriteToFileVerbosity" ]; then
      set_config_value "saved_log_WriteToFileVerbosity" "$log_WriteToFileVerbosity"
    else
      set_config_value "saved_log_WriteToFileVerbosity" "__unset__"
    fi
  fi
  set_config_value "log_WriteToFileVerbosity" 3
}

# Function to enable VNC server if configured
function enable_vnc {
  if [ "$(bool_check "$(get_config_value "enable_vnc")")" != 1 ]; then
    return
  fi
  ## Get the VNC password from the config file or generate a random one if not provided
  VNC_PASSWORD=$(get_config_value "vnc_password")
  if [ -z "$VNC_PASSWORD" ]; then
    VNC_PASSWORD=$(generate_password)
    set_config_value "vnc_password" "$VNC_PASSWORD"
  fi

  ## Start VNC server
  echo "Starting VNC server..."
  x11vnc -display :0 -forever -passwd $VNC_PASSWORD -listen 0.0.0.0 -no6 -xkb -rfbport 5900 -quiet &
}

# Function to generate a random password
function generate_password {
  local random_string=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
  echo $random_string
}

# Function to get clan members' Steam IDs from the database
function get_clan_members {
  local clan_ids=("$@")
  local clan_ids_str=$(IFS=,; echo "${clan_ids[*]}")
  local sql="SELECT (AccountID + 76561197960265728) AS SteamID FROM ClanMembers WHERE ClanID IN (${clan_ids_str})"
  local member_ids=()
  
  while IFS= read -r line; do
    member_ids+=("$line")
  done < <(sqlite3 /app/miscreated.db "$sql")
  
  echo "${member_ids[@]}"
}

# Function to get a configuration value from the config file
function get_config_value {
  local key=$1
  local value=$(grep -i -oP "(?<=^${key}=).*" ${CONFIG_FILE})
  value=$(echo "$value" | sed -E 's/\\#/#/g; s/#.*//')
  echo $value
}

# Function to get a configuration value as an array from the config file
function get_config_value_as_array {
  local key=$1
  local value=$(grep -i -oP "(?<=^${key}=).*" ${CONFIG_FILE})
  value=$(echo "$value" | sed -E 's/\\#/#/g; s/#.*//')
  IFS=';' read -r -a array <<< "$value"
  echo "${array[@]}"
}

# Function to get the map name from the config file, defaulting to "islands"
function get_map {
  local map=$(get_config_value "map")
  if [ -z "$map" ]; then
    map="islands"
  fi
  echo $map
}

# Function to get the maximum number of players from the config file, defaulting to 50
function get_maxplayers {
  local maxplayers=$(get_config_value "sv_maxplayers")
  if [ -z "$maxplayers" ]; then # Set default maxplayers to 50 if not provided
    maxplayers=50
  fi
  if ! [[ "$maxplayers" =~ ^[1-9][0-9]?$|^100$ ]]; then # Check if maxplayers is a number between 1 and 100. Reset to 50 if not.
    maxplayers=50
  fi
  echo $maxplayers
}

# Function to get the whitelist flag from the config file
function get_whitelisted {
  local whitelisted=$(bool_check "$(get_config_value "whitelisted")")
  if [ "$whitelisted" == 1 ]; then
    echo "-mis_whitelist"
  fi
}

# Function to get preservation IDs from the config file and clan members
function get_preservation_ids {
  local preservation_ids=($(get_config_value_as_array "preservation_ids"))
  local preservation_clans=($(get_config_value_as_array "preservation_clans"))
  local extracted_ids=($(get_clan_members "${preservation_clans[@]}"))
  local combined_ids=("${preservation_ids[@]}" "${extracted_ids[@]}")
  
  # Remove duplicates
  local unique_ids=($(echo "${combined_ids[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  
  echo "${unique_ids[@]}"
}

# Function to grant crafting guides to all players if configured
function grant_all_guides {
  if [ "$(bool_check "$(get_config_value "grant_guides")")" == 1 ] && [ -f /app/miscreated.db ]; then
  echo "Granting crafting guides to all players..."
  sqlite3 /app/miscreated.db <<EOF
DROP TRIGGER IF EXISTS grant_all_guides;
CREATE TRIGGER IF NOT EXISTS grant_all_guides 
AFTER UPDATE ON Characters 
BEGIN 
  UPDATE ServerAccountData 
  SET Guide00="-1", Guide01="-1"; 
END;
UPDATE ServerAccountData 
SET Guide00="-1", Guide01="-1";
EOF
  else
    echo "Database not found. Granting guides will be performed on the next server restart."
  fi
}

# Function to randomize the server uptime if configured
function randomized_uptime {
  if [ "$(bool_check "$(get_config_value "randomized_uptime")")" != 1 ]; then
    return
  fi
  min_val=$(get_config_value "min_uptime")
  if [ -z "$min_val" ]; then
    min_val=8
  fi

  max_val=$(get_config_value "max_uptime")
  if [ -z "$max_val" ]; then
    max_val=12
  fi

  random_val=$(awk -v min="$min_val" -v max="$max_val" 'BEGIN{srand(); print min+rand()*(max-min)}')
  random_val=$(printf "%.1f" "$random_val")

  set_config_value "sv_maxuptime" "$random_val"
}

# Function to remove a configuration value from the config file
function remove_config_value {
  local key=$1
  local temp_file=$(mktemp)
  sed "/^${key}=/Id" ${CONFIG_FILE} > ${temp_file}
  cat ${temp_file} > ${CONFIG_FILE}
  rm -f ${temp_file}
}

# Function to set a configuration value in the config file
function set_config_value {
  local key=$1
  local value=$2
  local temp_file=$(mktemp)
  if grep -qi "^${key}=" ${CONFIG_FILE}; then
    sed "s/^\(${key}\)=.*/\1=${value}/I" ${CONFIG_FILE} > ${temp_file}
    cat ${temp_file} > ${CONFIG_FILE}
  else
    echo "${key}=${value}" >> ${CONFIG_FILE}
  fi
  rm -f ${temp_file}
}

# Function to set a default HTTP password if not configured
function set_default_http_password {
  local rcon_password=$(get_config_value "http_password")
  if [ -z "$rcon_password" ]; then
    rcon_password=$(generate_password)
    set_config_value "http_password" "$rcon_password"
  fi
}

# Function to set a default map if not configured
function set_default_map {
  local map=$(get_config_value "map")
  if [ -z "$map" ]; then
    map="islands"
    set_config_value "map" "$map"
  fi
}

# Function to set a default server name if not configured
function set_default_sv_servername {
  local server_name=$(get_config_value "sv_servername")
  if [ -z "$server_name" ]; then
    local epoch_time=$(date +%s)
    local md5_hash=$(echo -n "$epoch_time" | md5sum | awk '{print substr($1, 1, 8)}')
    server_name="Miscreated Server ${md5_hash}"
    set_config_value "sv_servername" "$server_name"
  fi
}

# Function to set a default maximum number of players if not configured
function set_default_sv_maxplayers {
  local sv_maxplayers=$(get_config_value "sv_maxplayers")
  if [ -z "$sv_maxplayers" ]; then
    sv_maxplayers=50
    set_config_value "sv_maxplayers" "$sv_maxplayers"
  fi
}

# Function to set a default maximum uptime if not configured
function set_default_sv_maxuptime {
  local sv_maxuptime=$(get_config_value "sv_maxuptime")
  if [ -z "$sv_maxuptime" ]; then
    sv_maxuptime=12
    set_config_value "sv_maxuptime" "$sv_maxuptime"
  fi
}

# Function to update abandon timers for all bases, tents, or vehicles based on configuration
function update_all_abandon_timers {
  if [ ! -f /app/miscreated.db ]; then
    echo "Database not found. Abandon timers will not be updated."
    return
  fi
  if [ "$(sqlite3 /app/miscreated.db ".tables" | wc -l)" -eq 0 ]; then
    echo "The database is currently empty. Abandon timers will not be updated."
    return
  fi
  local sql=""
  case "$1" in
    bases)
      if [ "$(bool_check "$(get_config_value "reset_all_bases")")" == 1 ]; then
        echo "Resetting all bases..."
        sql="UPDATE Structures SET AbandonTimer=2419200 WHERE ClassName='PlotSign';"
      fi
      ;;
    tents)
      if [ "$(bool_check "$(get_config_value "reset_all_tents")")" == 1 ]; then
        echo "Resetting all tents_sql..."
        sql="UPDATE Structures SET AbandonTimer=2419200 WHERE ClassName like '%tent%';"
      fi
      ;;
    vehicles)
      if [ "$(bool_check "$(get_config_value "reset_all_vehicles")")" == 1 ]; then
        echo "Resetting all vehicles..."
        sql="UPDATE Vehicles SET AbandonTimer=2419200;"
      fi
      ;;
    despawn_vehicles)
      if [ "$(bool_check "$(get_config_value "reset_all_vehicles")")" == 1 ]; then
        echo "reset_all_vehicles setting takes precedence over despawn_vehicles setting."
      else
        local despawn_vehicles_value=$(get_config_value "despawn_vehicles")
        if [[ "$despawn_vehicles_value" =~ ^[0-9]+$ && "$despawn_vehicles_value" -gt 0 ]]; then
          echo "Setting vehicle despawn timer to $despawn_vehicles_value seconds..."
          sql="UPDATE Vehicles SET AbandonTimer=${despawn_vehicles_value};"
        fi
      fi
      ;;
    *)
      echo "Invalid argument. Please specify 'bases', 'tents', or 'vehicles'."
      ;;
  esac
  if [[ -n "$sql" ]]; then
    sqlite3 /app/miscreated.db "$sql"
  fi
}

# Function to update abandon timers for preserved bases, tents, and vehicles based on configuration
function update_preserved_abandon_timers {
  if [ ! -f /app/miscreated.db ]; then
    echo "Database not found. Abandon timers will not be updated."
    return
  fi
  if [ "$(sqlite3 /app/miscreated.db ".tables" | wc -l)" -eq 0 ]; then
    echo "The database is currently empty. Abandon timers will not be updated."
    return
  fi
  local sql=""
  local ids=($(get_preservation_ids))
  local ids_str=$(IFS=,; echo "${ids[*]}")
  get_preserved_bases_sql="""
  SELECT (AccountID + 76561197960265728) AS Owner,
    ROUND(PosX,5) AS PosX,
    ROUND(PosY,5) AS PosY
  FROM Structures
  WHERE ClassName='PlotSign' AND AccountID IN ($(echo $ids_str | sed 's/[0-9]\+/(& - 76561197960265728)/g'))
  """
  local preserved_bases=($(sqlite3 /app/miscreated.db "$get_preserved_bases_sql"))

  if [ "$(bool_check "$(get_config_value "preserve_bases")")" == 1 ]; then
    for base in "${preserved_bases[@]}"; do
      IFS='|' read -r owner posX posY <<< "$base"
      sql+="UPDATE Structures SET AbandonTimer=2419200 WHERE AccountID=$owner;"
    done
  fi

  if [ "$(bool_check "$(get_config_value "preserve_tents")")" == 1 ]; then
    for base in "${preserved_bases[@]}"; do
      IFS='|' read -r owner posX posY <<< "$base"
      sql+="UPDATE Structures SET AbandonTimer=2419200 WHERE ClassName LIKE '%tent%' AND ROUND(PosX,5) BETWEEN $(echo "$posX - 30" | bc) AND $(echo "$posX + 30" | bc) AND ROUND(PosY,5) BETWEEN $(echo "$posY - 30" | bc) AND $(echo "$posY + 30" | bc);"
    done
  fi

  if [ "$(bool_check "$(get_config_value "preserve_vehicles")")" == 1 ]; then
    for base in "${preserved_bases[@]}"; do
      IFS='|' read -r owner posX posY <<< "$base"
      sql+="UPDATE Vehicles SET AbandonTimer=2419200 WHERE ROUND(PosX,5) BETWEEN $(echo "$posX - 30" | bc) AND $(echo "$posX + 30" | bc) AND ROUND(PosY,5) BETWEEN $(echo "$posY - 30" | bc) AND $(echo "$posY + 30" | bc);"
    done
  fi

  if [[ -n "$sql" ]]; then
    sqlite3 /app/miscreated.db "$sql"
  fi
}

CONFIG_FILE=/app/docker.cfg
if [ "$(bool_check "$(get_config_value "debug")")" == 1 ]; then
  set -x
  enable_debug_logging;
else
  disable_debug_logging;
fi

# Update the game server if force_validation config value exists and is true
if [ "$(bool_check "$(get_config_value "force_validation")")" == 1 ]; then
  # /steamcmd/steamcmd.sh +force_install_dir /app +login anonymous +app_update 443030 validate +quit
  steamcmd +force_install_dir /app +login anonymous +app_update 443030 validate +quit
fi

# Start X virtual framebuffer
export WINEDLLOVERRIDES="mscoree,mshtml="
export XDG_RUNTIME_DIR=$(mktemp -d)
Xvfb :0 -screen 0 1280x1024x16 &

# Wait to ensure Xvfb is up
sleep 5

# Run the server
while [ ! -f /data/stop ]; do
  cd /app
  # Set defaults for new servers
  set_default_http_password; # Set default RCON password if http_password config value does not exist
  set_default_sv_servername; # Set default server name if sv_servername config value does not exist
  set_default_sv_maxuptime; # Set default max uptime if sv_maxuptime config value does not exist
  set_default_sv_maxplayers; # Set default max players if sv_maxplayers config value does not exist
  set_default_map; # Set default map if map config value does not exist. Default to islands.
  enable_vnc; # Enable VNC if enable_vnc config value exists and is true
  grant_all_guides; # Conditionally grant guides to all players if grant_guides config value exists. Config grant_guides value must be true.
  update_all_abandon_timers bases; # Extend abandon timer to 2419200 (seconds) for all bases if reset_all_bases config value exists and is true
  update_all_abandon_timers tents; # Extend abandon timer to 2419200 (seconds) for all tents if reset_all_tents config value exists and is true
  update_all_abandon_timers vehicles; # Extend abandon timer to 2419200 (seconds) for all vehicles if reset_all_vehicles config value exists and is true
  update_all_abandon_timers despawn_vehicles; # Set vehicle despawn timer if despawn_vehicles config value exists and is a positive integer (seconds)
  update_preserved_abandon_timers; # Extend abandon timer to 2419200 (seconds) for all bases, tents, and vehicles within 30m of a preservation plot sign if preserve_bases, preserve_tents, or preserve_vehicles config values exist and are true 
  randomized_uptime; # Randomize the server uptime if randomized_uptime config value exists and is true. This helps prevent server restarts from being predictable.
  MAXPLAYERS=$(get_maxplayers) # Get the sv_maxplayers number from the config file
  MAP=$(get_map) # Get the map from the config file
  WHITELISTED=$(get_whitelisted) # Get the whitelist flag from the config file

  echo "Starting Miscreated server with this command:"  
  echo "wine Bin64_dedicated/MiscreatedServer.exe +sv_maxplayers ${MAXPLAYERS} +map ${MAP} +http_startserver ${WHITELISTED}"
  wine64 Bin64_dedicated/MiscreatedServer.exe +sv_maxplayers ${MAXPLAYERS} +map ${MAP} +http_startserver ${WHITELISTED} &
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