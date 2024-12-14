# Dockerfile to run Conan Exiles server using Wine on Ubuntu

# Use the latest Ubuntu Server 22.04 as the base image
FROM ubuntu:jammy

# Set build arguments with default values
ARG USER=steam
ARG UID=1001
ARG GID=1001

# Set environment variables
ENV LD_LIBRARY_PATH="/app"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0

# Install required dependencies
RUN dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key - && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt-get update && \
    apt-get install -y --install-recommends \
    apt-transport-https \
    cabextract \
    curl \
    fonts-wine \
    gnupg2 \
    libwine \
    libwine:i386 \
    software-properties-common \
    sqlite3 \
    unzip \
    wget \
    winbind \
    winehq-stable \
    x11vnc \
    xvfb && \
    rm -rf /var/lib/apt/lists/*

# Create a group and user with the specified GID and UID if they do not exist
RUN if ! getent group $GID; then groupadd -g $GID $USER; fi && \
    if ! id -u $UID >/dev/null 2>&1; then useradd -m -u $UID -g $GID -s /bin/bash $USER; fi

# Install SteamCMD
RUN mkdir -p /steamcmd && \
    cd /steamcmd && \
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xvzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz && \
    chown -R $UID:$GID /steamcmd

# Create server install directory and set ownership and permissions
RUN mkdir -p /app && \
    chown -R $UID:$GID /app && \
    chmod -R 755 /app

# Install the server files
USER $USER
RUN /steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir /app +app_update 302200 validate +quit
USER root

# Copy the entrypoint script into the container
COPY image-scripts/start_server.sh /start_server.sh
RUN chmod +x /start_server.sh

# Set the working directory to the server directory /app
WORKDIR /app

# Expose the game server ports
EXPOSE 5900/tcp 64090/udp 64091/udp 64092/udp 64093/udp 64094/tcp

# Create the /tmp/.X11-unix directory and set permissions
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Switches the current user to the one specified by the $USER environment variable
USER $USER

# Set the entrypoint
ENTRYPOINT ["/start_server.sh"]