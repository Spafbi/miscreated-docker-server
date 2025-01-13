#!/usr/bin/env bash
CONTAINER_NAME=miscreated-server
GAME_PORT=64090
HOSTDIR=/home/steam/game-servers/miscreated
USER=steam

# Note: Do not edit below this line unless you are familiar with bash and Docker.

create_directory() {
  if sudo [ ! -d "$1" ]; then
    sudo mkdir -p "$1"
    sudo chown -R ${USER}: "$1"
  fi
}

ensure_file_exists() {
  if sudo [ ! -f "$1" ]; then
    sudo touch "$1"
    sudo chown ${USER}: "$1"
  fi
}

generic_hosting_cfg() {
  echo """
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
""" | base64 -d |gzip -d -c
}

# This function outputs a long text message to the console.
ouput_long_text() {
    local input_string="$1"
    local terminal_width=$(tput cols)
    local current_line=""
    local word
    local stripped_word

    for word in $input_string; do
        stripped_word=$(echo "$word" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        if [ ${#current_line} -eq 0 ]; then
            current_line="$word"
        elif [ $((${#current_line} + ${#stripped_word} + 1)) -le $terminal_width ]; then
            current_line="$current_line $word"
        else
            echo -e "$current_line"
            current_line="$word"
        fi
    done

    if [ ${#current_line} -ne 0 ]; then
        echo -e "$current_line"
    fi
}

# Check if the script is run as root or with sudo privileges
if [ "$EUID" -ne 0 ]; then
  ouput_long_text "As directories may be created and directory permissions changed, this script requires elevated permissions to allow these portions of the script to function as expected."
fi

# Check if the script is run as root or with sudo privileges.
if [ "$EUID" -ne 0 ] && ! sudo -v > /dev/null 2>&1; then
  ouput_long_text "Please run the script with sudo (preferred) or as root."
  exit 1
fi

# Ensure directories exist
create_directory ${HOSTDIR}/DatabaseBackups
create_directory ${HOSTDIR}/logbackups
create_directory ${HOSTDIR}/logs

# Ensure files exist with sudo
ensure_file_exists ${HOSTDIR}/banned.xml
ensure_file_exists ${HOSTDIR}/docker.cfg
ensure_file_exists ${HOSTDIR}/hosting.cfg
ensure_file_exists ${HOSTDIR}/miscreated.db
ensure_file_exists ${HOSTDIR}/reservations.xml
ensure_file_exists ${HOSTDIR}/whitelist.xml

# if sudo [ ! -f "${HOSTDIR}/hosting.cfg" ]; then
#   generic_hosting_cfg > "${HOSTDIR}/hosting.cfg"
#   sudo chown ${USER}: "${HOSTDIR}/hosting.cfg"
# fi

ouput_long_text -e "\e[4;94mThis server will use the following ports:\e[0m"
ouput_long_text -e "\e[33m${GAME_PORT}/udp\e[0m - Game server port for client connections"
ouput_long_text -e "\e[33m$((GAME_PORT + 1))/udp\e[0m - Game server port for Steam query"
ouput_long_text -e "\e[33m$((GAME_PORT + 2))/udp\e[0m - Game server port for server info"
ouput_long_text -e "\e[33m$((GAME_PORT + 3))/udp\e[0m - Game server port for VoIP"
ouput_long_text -e "\e[33m$((GAME_PORT + 4))/tcp\e[0m - Game server port for RCON (firewall ports should only be opened if you want to make this accessible externally, otherwise use direct LAN connections or SSH port tunneling)"
ouput_long_text "At a minimum, open the UDP ports to make the server available to players outside of your network. This means configuring your firewall to allow incoming traffic on the UDP ports (${GAME_PORT}, $((GAME_PORT + 1)), $((GAME_PORT + 2)), $((GAME_PORT + 3)))."

# Run Docker container
docker run -d --name "${CONTAINER_NAME}" \
    -p ${GAME_PORT}:64090/udp \
    -p $((GAME_PORT + 1)):64091/udp \
    -p $((GAME_PORT + 2)):64092/udp \
    -p $((GAME_PORT + 3)):64093/udp \
    -p $((GAME_PORT + 4)):64094/tcp \
    --restart always \
    -v "${HOSTDIR}/DatabaseBackups:/app/DatabaseBackups" \
    -v "${HOSTDIR}/logbackups:/logbackups" \
    -v "${HOSTDIR}/logs:/app/logs" \
    -v "${HOSTDIR}/banned.xml:/app/banned.xml" \
    -v "${HOSTDIR}/docker.cfg:/app/docker.cfg" \
    -v "${HOSTDIR}/hosting.cfg:/app/hosting.cfg" \
    -v "${HOSTDIR}/miscreated.db:/app/miscreated.db" \
    -v "${HOSTDIR}/reservations.xml:/app/reservations.xml" \
    -v "${HOSTDIR}/whitelist.xml:/app/whitelist.xml" \
    miscreated-server