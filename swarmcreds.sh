#!/bin/sh

# MIT License
#
# Copyright (c) 2019 Micah Culpepper
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


set -e


# Get a list of all credential names

names=$(docker secret ls --format '{{.Name}}')
if [ -z "$names" ]; then
    (>&2 echo "No swarm secrets to check.")
    exit 0
fi


# Build the image we will use for accessing credentials

cat << EOF | docker build -t swarmcreds:latest . -f -
FROM alpine:latest
CMD ["sh", "-c", "while /bin/true ; do sleep 5; done"]
EOF


# Create a docker-compose file in memory and use it to deploy a new stack on this host
# that will give us access to the credentials we're looking for

nodeid=$(docker node ls --format '{{.Self}}\t{{.ID}}' | awk '/true/ {print $2}')
secretlist=swarmcreds.secretlist.tmp
printf "" > "$secretlist"
secretsection=swarmcreds.secretsection.tmp
printf "" > "$secretsection"
for name in $names; do
    printf "\n      - %s" "$name" >> "$secretlist"
    printf "\n  %s:\n    external: true" "$name" >> "$secretsection"
done

cat << EOF | docker stack deploy -c - swarmcreds
version: '3.7'
services:
  swarmcreds:
    image: swarmcreds
    deploy:
      placement:
        constraints:
          - node.id == ${nodeid}
    secrets: $(cat "$secretlist")

    networks:
      - default

secrets: $(cat "$secretsection")

networks:
  default:
EOF


# Wait a bit for it to start, then get the ID of the running container we just made

sleep 2
containerid=$(\
    docker inspect "$(docker stack ps -q swarmcreds)" \
    --format '{{.Status.ContainerStatus.ContainerID}}')


# Use the new container to gather credentials

for name in $names; do
    secret=$(docker exec "$containerid" /bin/cat "/run/secrets/${name}")
    printf "%s\t%s\n" "$name" "$secret"
done


# Clean up

rm "$secretlist" "$secretsection"
docker stack rm swarmcreds
