# Dockerfile to run a Miscreated server using Wine on Ubuntu
# Set build arguments with default values
ARG USER=steam
ARG UID=1001
ARG GID=1001
ARG UBUNTU_CODENAME=jammy

# Use Ubuntu Server as the base image
FROM ubuntu:${UBUNTU_CODENAME}

# Set environment variables
ENV LD_LIBRARY_PATH="/app"

RUN dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_CODENAME}/winehq-${UBUNTU_CODENAME}.sources && \
    apt update && \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt install -y screen sudo wget && \
    echo steam steam/question select "I AGREE" | sudo debconf-set-selections && \
    echo steam steam/license note '' | sudo debconf-set-selections && \
    apt install -y --install-recommends winehq-stable steamcmd lib32gcc-s1 xvfb && \
    apt dist-upgrade -y && \
    apt upgrade -y && \
    apt autoremove -y && \
    if ! getent group $GID; then groupadd -g $GID $USER; fi && \
    if ! id -u $UID >/dev/null 2>&1; then useradd -m -u $UID -g $GID -s /bin/bash $USER; fi

# Create server install directory and set ownership and permissions
RUN mkdir -p /app && \
    chown -R $UID:$GID /app && \
    chmod -R 775 /app

# Set the working directory to the server directory /app
WORKDIR /app

# Set the user to steam ($USER)
USER $USER

# Copy the run-server.sh script to the /app directory
COPY files/miscreated.sh /app/

RUN mkdir -p ~/.steam 2>/dev/null && \
    XAUTH=$(mktemp) && \
    XDUMP=~/.miscreated-xdump && \
    export WINEPREFIX="~/.wine" && \
    export WINEDLLOVERRIDES="mscoree,mshtml=" && \
    WINEDEBUG=-fixme-all xvfb-run -e ${XDUMP} -f ${XAUTH} -a wineboot -u
    /usr/games/steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "/app" +login anonymous +app_update 302200 validate +quit

# Expose the necessary UDP and TCP ports
EXPOSE 64090-64093/udp
EXPOSE 64094/tcp

# Set the entrypoint to the miscreated.sh script
ENTRYPOINT ["/app/miscreated.sh"]