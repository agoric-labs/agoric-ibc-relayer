#!/bin/bash

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 CHAIN1_ID CHAIN2_ID ALICE_KEY BOB_KEY CONFIG_FILE"
    exit 1
fi

CHAIN1_ID=$1
CHAIN2_ID=$2
ALICE_KEY=$3
BOB_KEY=$4
CONFIG_FILE=$5


hermes --config $CONFIG_FILE keys add --chain $CHAIN1_ID --mnemonic-file $ALICE_KEY
hermes --config $CONFIG_FILE keys add --chain $CHAIN2_ID --mnemonic-file $BOB_KEY


timeout 300 bash -c '
TARGET_HEIGHT=1261
SLEEP=10
echo "Waiting for the Agoric service to be fully ready..."
echo "Target block height: $TARGET_HEIGHT"
while true; do
    response=$(curl --silent http://agoric-local:26657/abci_info);
    height=$(echo $response | jq -r ".result.response.last_block_height | tonumber");
    if [ "$height" -ge $TARGET_HEIGHT ]; then
    echo "Service is ready! Last block height: $height";
    break;
    else
    echo "Waiting for last block height to reach $TARGET_HEIGHT. Current height: $height";
    fi;
    sleep $SLEEP;
done
'
hermes --config $CONFIG_FILE create channel --a-chain $CHAIN1_ID --b-chain $CHAIN2_ID --a-port transfer --b-port transfer --new-client-connection --yes

hermes --config $CONFIG_FILE start
