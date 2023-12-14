#!/usr/bin/env bash

# Number of addresses to send funds to in each TX
max_num_outputs=1200
fee_rate=0.0008

set -eo pipefail

start_time=$(date +%s)

# Declare an array to store new addresses
declare -a addresses

generate_p2tr_address() {
    nigiri rpc getnewaddress some_label bech32m
}

# Caution: The script is significantly faster if you send to addresses that do NOT belong to your Bitoin Core's wallet.
script_dir="$(dirname "$(readlink -f "$0")")"
address_caching_file="/$script_dir/regtest_addresses"
if [ -e "$address_caching_file" ] && [ $(cat $address_caching_file | wc -l) -gt $(($max_num_outputs -1)) ]; then
    declare -a read_addresses
    while IFS= read -r line; do
        read_addresses+=("$line")
    done < "$address_caching_file"
    addresses=(${read_addresses[@]:0:$max_num_outputs})
else
    echo "[  0 sec] Generating $max_num_outputs addresses"
    for ((i=1; i<=max_num_outputs; i++)); do
        addresses+=("$(generate_p2tr_address)")
    done

    # Cache the generated addresses
    for address in "${addresses[@]}"; do
        echo "$address" >> $script_dir/regtest_addresses
    done

fi

jsonify_array() {
    outputs=("$@")
    json_outputs="["
    for ((i=0; i<${#outputs[@]}; i++)); do
        json_outputs+="{\"${outputs[i]}\": $(printf "0.0000%02d" $((i % 10 + 5)))},"
    done
    json_outputs="${json_outputs%,}"  # Remove the trailing comma
    json_outputs+="]"

    echo $json_outputs
}

num_blocks=100
echo "[$(printf '%3d' $(expr $(date +%s) - $start_time)) sec] Mining $num_blocks blocks to fund wallet"
nigiri rpc generatetoaddress $num_blocks "$(generate_p2tr_address)" > /dev/null

create_tx() {
    outputs=${addresses[@]:0:$1}
    json_outputs=$(jsonify_array $outputs)
    fee_rate=$2
	
    rawtx=$(nigiri rpc createrawtransaction "[]" "$json_outputs")
    fundedtx=$(nigiri rpc fundrawtransaction "$rawtx" "{\"feeRate\": \"$fee_rate\"}" | jq -r ".hex")
    signedtx=$(nigiri rpc signrawtransactionwithwallet "$fundedtx" | jq -r ".hex")
    senttx=$(nigiri rpc sendrawtransaction "$signedtx")	
}

next_block_weight() {
    echo $(nigiri rpc getblocktemplate '{"rules": ["segwit"]}' | jq '.transactions | map(.weight) | add')
}

max_block_weight(){
    echo $(nigiri rpc getblocktemplate '{"rules": ["segwit"]}' | jq '.weightlimit')
}
max_block_weight=$(max_block_weight)

echo "[$(printf '%3d' $(expr $(date +%s) - $start_time)) sec] Starting to generate TXs"

block_filled=0
counter=0
while true; do
    ((++counter))
    if (( $(echo "$block_filled < 0.91" | bc -l) )); then
        outputs_amount=${#addresses[@]}
    else
        range=$(echo "3^((1 - $block_filled) * 80 + 2)" | bc -l 2>/dev/null)
	safe_range=$(( $range % max_num_outputs ))
        outputs_amount=$((1 + RANDOM % $safe_range))
    fi

    create_tx $outputs_amount $fee_rate

    if [ $counter -gt 20 ]; then
        sleep 1 # Give Bitcoin Core some time to process the new TX
        next_block_weight=$(next_block_weight)
        block_filled=$(echo "scale=4; $next_block_weight / $max_block_weight" | bc)
        block_filled_percentage=$(printf "%.2f" $(echo "scale=2; $block_filled * 100" | bc))
        left_space_in_next_block=$(($max_block_weight - $next_block_weight))
	echo "[$(printf '%3d' $(expr $(date +%s) - $start_time)) sec] TX created (Next block: [Filled: $block_filled_percentage%, vBytes left: $left_space_in_next_block], total TX data: $(($(nigiri rpc getmempoolinfo | jq -r .bytes) / 10000))%)"
    fi
done
