[![Build Status](https://travis-ci.org/micahculpepper/swarmcreds.svg?branch=master)](https://travis-ci.org/micahculpepper/swarmcreds)

# swarmcreds

Show the secrets stored in your Docker Swarm.

## Example

```
[root@docker-host ~]# ./swarmcreds.sh
apikey	9FuBmQbw
passwd	AVJN7Ckq
```

## Motivation

Sometimes passwords, SSL keys, etc. change and will need to be udpated in a production environment.
Updating a swarm secret requires restarting the affected services twice. I wanted a way to ensure
parity between my swarm secrets and my other password stores without forcing service restarts.
There are docker commands to set/update swarm secrets, but no commands to show existing secrets,
so I made one.

## Requirements

- Linux
- Docker
- A POSIX compliant shell at `/bin/sh`


## Installation

1. Download [swarmcreds.sh](https://github.com/micahculpepper/swarmcreds/raw/master/swarmcreds.sh) and save it
wherever you like.

2. Make sure `swarmcreds.sh` is executable: `chmod +x swarmcreds.sh`

3. Symlink `swarmcreds.sh` to a program directory. Example:

```bash
# From the directory containing swarmcreds.sh:
ln -s "$(pwd)/swarmcreds.sh" /usr/local/bin/swarmcreds
```

## Usage

Simply execute the script as a user with Docker permissions. Output is tab-separated. 
There are no option flags.

## Method

This script works by using `docker secret ls` to get a list of all existing secret names, 
spinning up a new docker service that has access to all of the secrets, and then reading them.
