# IBC Testing with Local Chains

## Build Docker images

Clone the repo and run the following command to build agoric chain image.

```
$ docker build -t a3p:local .
```

## Start the network

The following command starts the network with two agoric chains and a relayer.

```
$ docker-compose up -d
```

## Transfer some token

Make sure that chains are up and running, and the relayer is initialized. The following command should say that the hermes relayer has started:

```
$ docker logs -f relayer
```

The chains are set up with pre-existing accounts that are already funded with tokens. To inspect the token balances of these accounts, open a new terminal window and execute the following commands:

```
$ docker exec agoric-local-1 agd query bank balances agoric1myfpdaxyj34lqexe9cypu6vrf34xemtfq2a0nt
$ docker exec agoric-local-2 agd query bank balances agoric1aczzle80960fc0vq8gemjuu8ydrql07az7fmur
```

For conducting an IBC (Inter-Blockchain Communication) transaction using the relayer, use the following command:

```
$ docker exec relayer hermes --config /workspace/relayer/config.toml tx ft-transfer --src-chain agoric-local-1 --src-channel channel-0 \
 --dst-chain agoric-local-2 --src-port transfer --amount 100 --denom 'ubld' --timeout-seconds 1000
```

After completing the transaction, you should verify the account balances again to confirm the transfer.

# IBC Testing with Emerynet and Devnet

## Start the relayer

The following command starts the network with two agoric chains and a relayer.

```
$ docker-compose -f docker-compose-testnet.yaml up -d
```

## Transfer IBC tokens

Get the new channel ID got created from the relayer logs.

```
docker logs relayer
```

Use the new channel ID in the following command to transfer tokens from Emerynet to Devnet using IBC relayer.

```
$ docker exec relayer hermes --config /workspace/relayer/config-testnet.toml tx ft-transfer --src-chain agoric-emerynet-8 --src-channel <Channel-ID> \
 --dst-chain agoricdev-23 --src-port transfer --amount 100 --denom 'ubld' --timeout-seconds 1000
```

Verify the account balances to confirm the transfer for both Emerynet and Devnet.

On devnet

```
agd query bank balances agoric1khw65emzav9t0cdhj3aw9x2v7m60jekjdf4whl
```

On emerynet

```
agd query bank balances agoric10emrzln03exuc9uv98mjwmp95735mjm6k2n9xm
```

# IBC Testing with Emerynet and Local Chain

## Start the local chain

First, start your local chain using this command:

```
docker-compose -f docker-compose-testnet.yaml up -d agoric-local
```

## Check Local Chain Logs

To confirm that the local chain is running, monitor its logs:

```
docker logs agoric-local -f
```

Once you see messages showing blocks with a status of commit you can rest assured the chain is running properly:

```
2023-12-27T04:08:06.384Z block-manager: block 1003 begin
2023-12-27T04:08:06.386Z block-manager: block 1003 commit
2023-12-27T04:08:07.396Z block-manager: block 1004 begin
2023-12-27T04:08:07.398Z block-manager: block 1004 commit
2023-12-27T04:08:08.405Z block-manager: block 1005 begin
2023-12-27T04:08:08.407Z block-manager: block 1005 commit
```

## Start the Relayer

Next, start the Hermes relayer using this command:

```
docker-compose -f docker-compose-testnet.yaml up -d relayer
```

## Check Relayer Logs

Check the relayer's logs using this command:

```
docker logs relayer -f
```

### What to Look For

1. `Channel Initialization (OpenInitChannel)`: Watch for log entries indicating the start of a channel setup, such as:

```
2024-07-18T10:15:15.194536Z  INFO ThreadId(01) 🎊  agoric-emerynet-8 => OpenInitChannel(OpenInit { port_id: transfer, channel_id: channel-51, connection_id: None, counterparty_port_id: transfer, counterparty_channel_id: None }) at height 8-6169496
```

Note the channel_id (e.g., `channel-51`) from these entries, as it will be used in the follow-up steps.

2. `Channel Confirmation (OpenConfirmChannel)`: Ensure that the channel setup has been confirmed with a log entry like:

```
2024-07-18T10:17:09.873013Z  INFO ThreadId(01) 🎊  agoricdev-23 => OpenConfirmChannel(OpenConfirm { port_id: transfer, channel_id: channel-42, connection_id: connection-45, counterparty_port_id: transfer, counterparty_channel_id: channel-51 })
```

This confirmation is critical before attempting any transactions.

## Transfer IBC tokens

### Step 1: Retrieve the Channel ID

First, ensure you have the new channel ID from the relayer logs (from the previous steps), such as `channel-51`.

### Step 2: Execute the Transfer Command

Use the channel ID to execute the following command. Replace <Channel-ID> with the actual channel ID you noted earlier:

```
$ docker exec relayer hermes --config /workspace/relayer/config-testnet.toml tx ft-transfer --src-chain agoric-emerynet-8 --src-channel <Channel-ID> \
 --dst-chain agoric-local --src-port transfer --amount 100 --denom 'ubld' --timeout-seconds 1000
```

This command transfers 100 units of the `ubld` token from Emerynet to Local Chain.

If you need to transfer tokens from the Local Chain to Emerynet, you can use the `counterparty_channel_id` found in the logs. For reversing transfers, the command would typically use `channel-0` as follows:

```
docker exec relayer hermes --config /workspace/relayer/config-testnet.toml tx ft-transfer --src-chain agoric-local --src-channel channel-0 \
 --dst-chain agoric-emerynet-8 --src-port transfer --amount 100 --denom 'ubld' --timeout-seconds 1000

```

### Step 3: Verify the Transfer

Confirm that the transfer was successful by checking the account balances on both chains.

- **On local**:

```
curl http://localhost:1317/cosmos/bank/v1beta1/balances/agoric1myfpdaxyj34lqexe9cypu6vrf34xemtfq2a0nt
```

- **On emerynet**

```
curl https://emerynet.api.agoric.net/cosmos/bank/v1beta1/balances/agoric10emrzln03exuc9uv98mjwmp95735mjm6k2n9xm
```
