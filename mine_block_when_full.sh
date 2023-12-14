#!/usr/bin/env bash

max_block_weight=$(nigiri rpc getblocktemplate '{"rules": ["segwit"]}' | jq '.weightlimit')

while true; do
    next_block_weight=$(nigiri rpc getblocktemplate '{"rules": ["segwit"]}' | jq '.transactions | map(.weight) | add')
    block_filled=$(echo "scale=4; $next_block_weight / $max_block_weight" | bc)

    if (( $(echo "$(nigiri rpc getmempoolinfo | jq -r .bytes) > 1100000" | bc -l) )); then
        if (( $(echo "$block_filled > 0.9976" | bc -l) )); then
            nigiri rpc -generate 1
        fi 
    fi
    sleep 1
done

