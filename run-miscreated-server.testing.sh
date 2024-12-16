# #!/usr/bin/env bash
# CONTAINER_NAME=miscreated-server
# GAME_PORT=64090
# HOSTDIR=/home/steam/game-servers/miscreated
# USER=steam
# VNC_PORT=5900

# # Note: Do not edit below this line unless you are familiar with bash and Docker.

# create_directory() {
#   if sudo [ ! -d "$1" ]; then
#     sudo mkdir -p "$1"
#     sudo chown -R ${USER}: "$1"
#   fi
# }

# ensure_file_exists() {
#   if sudo [ ! -f "$1" ]; then
#     sudo touch "$1"
#     sudo chown ${USER}: "$1"
#   fi
# }

# # This function outputs a long text message to the console.
# ouput_long_text() {
#     local input_string="$1"
#     local terminal_width=$(tput cols)
#     local current_line=""
#     local word
#     local stripped_word

#     for word in $input_string; do
#         stripped_word=$(echo "$word" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
#         if [ ${#current_line} -eq 0 ]; then
#             current_line="$word"
#         elif [ $((${#current_line} + ${#stripped_word} + 1)) -le $terminal_width ]; then
#             current_line="$current_line $word"
#         else
#             echo -e "$current_line"
#             current_line="$word"
#         fi
#     done

#     if [ ${#current_line} -ne 0 ]; then
#         echo -e "$current_line"
#     fi
# }

# # Check if the script is run as root or with sudo privileges
# if [ "$EUID" -ne 0 ]; then
#   ouput_long_text "As directories may be created and directory permissions changed, this script requires elevated permissions to allow these portions of the script to function as expected."
# fi

# # Check if the script is run as root or with sudo privileges.
# if [ "$EUID" -ne 0 ] && ! sudo -v > /dev/null 2>&1; then
#   ouput_long_text "Please run the script with sudo (preferred) or as root."
#   exit 1
# fi

# # Ensure directories exist
# create_directory ${HOSTDIR}/DatabaseBackups
# create_directory ${HOSTDIR}/logbackups
# create_directory ${HOSTDIR}/logs

# # Ensure files exist with sudo
# ensure_file_exists ${HOSTDIR}/banned.xml
# ensure_file_exists ${HOSTDIR}/docker.cfg
# ensure_file_exists ${HOSTDIR}/hosting.cfg
# ensure_file_exists ${HOSTDIR}/miscreated.db
# ensure_file_exists ${HOSTDIR}/reservations.xml
# ensure_file_exists ${HOSTDIR}/whitelist.xml

# docker run -d --name "${CONTAINER_NAME}" \
#     -p ${VNC_PORT}:5900/tcp \
#     -p ${GAME_PORT}:64090/udp \
#     -p $((GAME_PORT + 1)):64091/udp \
#     -p $((GAME_PORT + 2)):64092/udp \
#     -p $((GAME_PORT + 3)):64093/udp \
#     -p $((GAME_PORT + 4)):64094/tcp \
#     --restart always \
#     -v "${HOSTDIR}/DatabaseBackups:/app/DatabaseBackups" \
#     -v "${HOSTDIR}/logbackups:/logbackups" \
#     -v "${HOSTDIR}/logs:/app/logs" \
#     -v "${HOSTDIR}/banned.xml:/app/banned.xml" \
#     -v "${HOSTDIR}/docker.cfg:/app/docker.cfg" \
#     -v "${HOSTDIR}/hosting.cfg:/app/hosting.cfg" \
#     -v "${HOSTDIR}/miscreated.db:/app/miscreated.db" \
#     -v "${HOSTDIR}/reservations.xml:/app/reservations.xml" \
#     -v "${HOSTDIR}/whitelist.xml:/app/whitelist.xml" \
#     miscreated-server

docker run -d --name miscreated-server -p 5900:5900/tcp -p 64090:64090/udp -p 64091:64091/udp -p 64092:64092/udp -p 64093:64093/udp miscreated-server