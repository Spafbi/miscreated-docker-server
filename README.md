# miscreated-docker-server
Automated setup and management of a Miscreated server using Docker.

# Table of Contents
- [Requirements](#requirements)
- [Files](#files)
- [Installation and Use Steps](#installation-and-use-steps)
    - [Download this Project](#download-this-project)
    - [Creating a "steam" User Account](#creating-a-steam-user-account)
    - [Building the Docker image](#building-the-docker-image)
        - [Build arguments](#build-arguments)
- [`hosting.cfg` Variables](#hostingcfg-variables)
    - [Standard Variables](#standard-variables)
    - [Whitelisting](#whitelisting)
    - [Validation and Updates](#validation-and-updates)
    - [Remote Console Access](#remote-console-access)
    - [Randomized Restart Times](#randomized-restart-times)
    - [Server Tricks](#server-tricks)
        - [Grant All Guides](#grant-all-guides)
        - [Anti Vehicle Hoarding](#anti-vehicle-hoarding)
        - [Permanent Bases, Tents, and Vehicles](#permanent-bases-tents-and-vehicles)
            - [Extend Abandon Timers](#extend-abandon-timers)
            - [Granular Abandon Timer Extension](#granular-abandon-timer-extension)

# Requirements
- **A Linux host**: Required to run the Docker containers. [Learn how to set up a Linux server](https://ubuntu.com/tutorials/install-ubuntu-server).
- **Docker**: Needed to create and manage the server container. [Install Docker](https://docs.docker.com/get-docker/).
- **sudo permissions**: Necessary to execute Docker commands and manage system configurations. Typically, the user account created during the Linux operating system installation already has sudo permissions assigned. [Understanding sudo](https://www.sudo.ws/). [Set up sudo on Ubuntu](https://ubuntu.com/server/docs/installing-sudo).

# Files
Here are the important files in this project. The Dockerfile and script (.sh) files are designed to accept arguments, so modifications are usually unnecessary.

- [`create-steam-account.sh`](./create-steam-account.sh): Helps new Linux administrators create a Steam user account for the server.
- [`Dockerfile`](./Dockerfile): Contains instructions for Docker to build the image for the Miscreated server.
- [`run-miscreated-server.sh`](./run-miscreated-server.sh): Starts the Miscreated server within a Docker container.
- [`start_server.sh`](./start_server.sh): Starts the Miscreated server inside the Docker container.

# Installation and Use Steps
## Download this Project
Clone the repository to your home directory:
```sh
cd ~
git clone https://github.com/spafbi/miscreated-docker-server.git ~/miscreated-docker-server
cd ~/miscreated-docker-server
chmod +x ~/miscreated-docker-server/*.sh
```

## Creating a "steam" User Account
Running a Docker container as a non-root user is beneficial for security reasons. The container defaults to using the `steam` user with UID and GID 1001. The `create-steam-account.sh` script helps create a local `steam` user account for running the Docker container. This local `steam` user is not associated with any Steam account and is only for local security controls.

Run the `create-steam-account.sh` script:
```sh
~/miscreated-docker-server/create-steam-account.sh
```
When this script runs, it will also inform you if any build arguments are required when creating the Docker image.

## Building the Docker image
Build the Docker image using the provided `Dockerfile`:
```sh
docker build -t miscreated-server .
```
### Build arguments
You can change the default user account, UID, and GID used in the Docker image by specifying build arguments. For example, to use a different user account with UID 2000 and GID 2000, you can run the following command:
```sh
docker build --build-arg USER=newuser --build-arg UID=2000 --build-arg GID=2000 -t miscreated-server .
```
You can also run the docker container as your own user. Here's a command for building the container using your username, UID, and GID:
```sh
docker build --build-arg USER=$(whoami) --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t miscreated-server .
```
> Note: If you do not use the default user of "steam", you will need to pass the user argument to the `run-miscreated-server.sh` script in that step. For more information, refer to the [Starting the Server](#starting-the-server) section.

### The directory structure
By default, the `run-miscreated-server.sh` script will create the following directory structure and files which looks like this:
```
/home/steam/game-servers/miscreated
├── DatabaseBackups/
├── logbackups/
│── logs/
│── banned.xml
│── hosting.cfg
│── reservations.xml
└── whitelist.xml
```

# Starting the server
## Starting the server

The `run-miscreated-server.sh` script uses the following default variables:
```ini
CONTAINER_NAME=miscreated-server
GAME_PORT=64090
HOSTDIR=/home/steam/game-servers/miscreated
USER=steam
VNC_PORT=5900
```
You can modify these variables to suit your preferences. If you plan to run multiple servers on the same host, copy the `run-miscreated-server.sh` script to a new file (e.g., `run-my-other-miscreated-server.sh`) and change at least the following:

- `CONTAINER_NAME`: Use a unique name (alphanumeric, dashes allowed, no spaces or special characters).
- `GAME_PORT`: Use increments of 5 (e.g., 64095, 64100, 64105, etc.).
- `VNC_PORT`: Increment this value by one for each additional server.

To start the Miscreated server with the default settings, run:
```sh
~/miscreated-docker-server/run-miscreated-server.sh
```
# Viewing the active server log
To view `server.log`, just use the Docker logs command:
```sh
docker logs miscreated-server
```
You can substitute *miscreated-server* with the name of the container if you are running more than one server. You may also follow the log as data is written to it by executing:
```sh
docker logs -f miscreated-server
```
If you want to search through the log contents, pipe the log through less and use the built-in search commands.
```sh
docker logs miscreated-server|less
```

# `hosting.cfg` Variables
The following variables used in the `start_server.sh` script can be set in the server's `hosting.cfg` file.

## Standard Variables
These variables are standard for the Miscreated server. If not defined, they will use their default values.
- `http_password`: RCON password for the server. (default: randomly generated)
- `map`: Map to be used by the server (default: islands)
- `sv_maxplayers`: Maximum number of players (default: 50)
- `sv_maxuptime`: Maximum server uptime in hours (default: 12)
- `sv_servername`: Server name (default: randomly generated)

**NOTE:** The following variables are specific to the Docker container's `start_server.sh` script and are not standard Miscreated server variables.

## Whitelisting
- `whitelisted`: Enable whitelist for the server (yes/no)(default: no)

## Validation and Updates
Enable forced updates and file validation by setting this option to "yes".
- `force_validation`: Force validation of the game server files (yes/no)(default: no)

## Remote Console Access
Use a VNC client to access the Miscreated server's console.
- `enable_vnc`: Enable the VNC server (yes/no)(default: no)
- `vnc_password`: Password for VNC server (default: randomly generated)

## Randomized Restart Times
The `randomized_uptime` option adds variability to server restart times, preventing predictable schedules. Adjust the `max_uptime` and `min_uptime` values to set the range for random restart intervals.
- `randomized_uptime`: Randomize server uptime (yes/no)(default: no)
- `max_uptime`: Maximum server uptime in hours. (default: 12)
- `min_uptime`: Minimum server uptime in hours. (default: 8)

## Server Tricks
The following options modify the Miscreated database before each server start or restart.

### Grant All Guides
- `grant_guides`: Automatically grant all crafting guides to every player. New players need to log out and log back in to access the guides. (yes/no)(default: no)

### Anti Vehicle Hoarding
- `despawn_vehicles`: Set the vehicle despawn timer in seconds. Do not set this value, or set it to -1, to disable this option. For example, setting this to 1800 seconds will make vehicles despawn 30 minutes after a server restart.

### Permanent Bases, Tents, and Vehicles
#### Extend Abandon Timers
Extend the abandon timers to their maximum values for the specified entities.
- `reset_all_bases`: Reset the abandon timer for all bases (yes/no)(default: no)
- `reset_all_tents`: Reset the abandon timer for all tents (yes/no)(default: no)
- `reset_all_vehicles`: Reset abandon timer for all vehicles (yes/no)(default: no)

#### Granular Abandon Timer Extension
Some servers may need to maintain specific bases, tents, or vehicles for events or moderation purposes. Use the `preservation_clans` and `preservation_ids` variables to prevent these entities from despawning. Enable preservation for each entity type by setting the corresponding variable to `yes`. Avoid using these options to give specific players an unfair advantage.
- `preservation_clans`: A semicolon-separated list of clan IDs to preserve. Clan IDs can be found in the `miscreated.db`.
- `preservation_ids`: A semicolon-separated list of SteamID64 values to preserve specific entities.
- `preserve_bases`: Preserve bases for preservation clans and IDs (yes/no)(default: no)
- `preserve_tents`: Preserve tents within 30 meters of preservation base plot signs (yes/no)(default: no)
- `preserve_vehicles`: Preserve vehicles within 30 meters of preservation base plot signs (yes/no)(default: no)