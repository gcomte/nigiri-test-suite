#!/usr/bin/env bash

# Closes the first channels that appears in the listchannels result.

if [ -z "$1" ]; then
    echo "Provide argument 'cln' or 'cln2' to define which node should be the initiatior to close the channel"
    exit 1
fi

# load aliases cln and cln2
script_dir="$(dirname "$(readlink -f "$0")")"
source $script_dir/alias.sh

close_initiating_node=$1 # 'cln' or 'cln2'

channel_id=$($close_initiating_node listchannels | jq -r .channels[0].short_channel_id)
$close_initiating_node close $channel_id 1
