#!/usr/bin/env bash

sudo chown -R $USER:$USER ~/.nigiri # fixes permission issue: https://github.com/vulpemventures/nigiri/issues/178
nigiri stop --delete # Also deletes docker-compose.yml

# Bring back the docker-compose.yml file.
script_dir="$(dirname "$(readlink -f "$0")")"
docker_compose_file="/$script_dir/docker-compose.yml"
cp $docker_compose_file ~/.nigiri
nigiri start --ln
docker-compose -f ~/.nigiri/docker-compose.yml up -d cln2
