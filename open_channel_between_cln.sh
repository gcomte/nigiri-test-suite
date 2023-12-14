#!/usr/bin/env bash

channel_size_sats=100000

# load aliases cln and cln2
script_dir="$(dirname "$(readlink -f "$0")")"
source $script_dir/alias.sh

echo -n "Funding CLN "
for ((i=1; i<=5; i++)); do
    while true; do # Repeat the command until it doesn't fail anymore (= nigiri is ready)
        nigiri faucet cln >/dev/null 2>&1
    	if [ $? -eq 0 ]; then
       	    break
    	fi
	echo -n "."
	sleep 0.1
    done
done

cln2_address="$(cln2 getinfo | jq -r .id)@cln2:9535"
cln connect $cln2_address > /dev/null

get_amount_of_channels() {
    echo $(($($1 listchannels | jq '.channels | length') / 2))
}
amount_of_channels_cln=$(get_amount_of_channels cln)
amount_of_channels_cln2=$(get_amount_of_channels cln2)
echo -e "\ncln has $amount_of_channels_cln channels"

echo -n "Waiting for CLN to get ready "
while true; do # Repeat the command until it doesn't fail anymore (= CLN found its UTXOs)
	channel_opening_response=$(cln fundchannel $cln2_address $channel_size_sats 2>/dev/null)
        if [ $? -eq 0 ]; then
            break
        fi
        echo -n "."
        sleep 1
    done
echo -e "\nChannel opening TX published"
channel_opening_txid=$(echo "$channel_opening_response" | jq -r .txid)

channel_size_in_thousands=$((channel_size_sats/1000))
echo "Opened ${channel_size_in_thousands}K sats channel [cln --> cln2]: $channel_opening_txid"


nigiri rpc -generate 1 > /dev/null

echo -n "Mined a block. Waiting for CLN to recognize its channel is open "

while [ $(get_amount_of_channels cln) -eq $amount_of_channels_cln ] || [ $(get_amount_of_channels cln2) -eq $amount_of_channels_cln2 ]; do
    sleep 1
    echo -n "."
done

echo -e "\nChannel confirmed"

amount_sat=$(($channel_size_sats / 10))
echo "Sending $amount_sat over the channel"
amount_msat=$(($amount_sat * 1000))
unique_label=$(echo "label$(date +%s)")
invoice=$(cln2 invoice $amount_msat $unique_label "description-lorem-ipsum" | jq -r .bolt11)

cln pay $invoice
