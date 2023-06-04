#!/bin/bash

KEY="mykey"
CHAINID="black_9000-1"
MONIKER="mymoniker"
DATA_DIR=$(mktemp -d -t black-datadir.XXXXX)

echo "create and add new keys"
./black keys add $KEY --home $DATA_DIR --no-backup --chain-id $CHAINID --algo "eth_secp256k1" --keyring-backend test
echo "init black with moniker=$MONIKER and chain-id=$CHAINID"
./black init $MONIKER --chain-id $CHAINID --home $DATA_DIR
echo "prepare genesis: Allocate genesis accounts"
./black add-genesis-account \
"$(./black keys show $KEY -a --home $DATA_DIR --keyring-backend test)" 1000000000000000000afury,1000000000000000000stake \
--home $DATA_DIR --keyring-backend test
echo "prepare genesis: Sign genesis transaction"
./black gentx $KEY 1000000000000000000stake --keyring-backend test --home $DATA_DIR --keyring-backend test --chain-id $CHAINID
echo "prepare genesis: Collect genesis tx"
./black collect-gentxs --home $DATA_DIR
echo "prepare genesis: Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
./black validate-genesis --home $DATA_DIR

echo "starting black node $i in background ..."
./black start --pruning=nothing --rpc.unsafe \
--keyring-backend test --home $DATA_DIR \
>$DATA_DIR/node.log 2>&1 & disown

echo "started black node"
tail -f /dev/null