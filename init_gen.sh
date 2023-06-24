KEY="watcher"
KEY2="watcher2"
CHAINID="highbury_710-1"
MONIKER="The-Watchers"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# to trace evm
#TRACE="--trace"
TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# Reinstall daemon
rm -rf ~/.evmosd*
make install

# Set client config
evmosd config keyring-backend $KEYRING
evmosd config chain-id $CHAINID

# if $KEY exists it should be deleted
evmosd keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO
evmosd keys add $KEY2 --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for Black (Moniker can be anything, chain-id must be an integer)
evmosd init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to ablack
cat $HOME/.evmosd/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="ablack"' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json
cat $HOME/.evmosd/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="ablack"' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json
cat $HOME/.evmosd/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="ablack"' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json
cat $HOME/.evmosd/config/genesis.json | jq '.app_state["evm"]["params"]["evm_denom"]="ablack"' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json
cat $HOME/.evmosd/config/genesis.json | jq '.app_state["inflation"]["params"]["mint_denom"]="ablack"' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json

# Change voting params so that submitted proposals pass immediately for testing
cat $HOME/.evmosd/config/genesis.json| jq '.app_state.gov.voting_params.voting_period="720s"' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json


# disable produce empty block
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.evmosd/config/config.toml
  else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.evmosd/config/config.toml
fi

if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "2s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "2s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "2s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.evmosd/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.evmosd/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "2s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "2s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "2s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.evmosd/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.evmosd/config/config.toml
  fi
fi

# Allocate genesis accounts (cosmos formatted addresses)
evmosd add-genesis-account $KEY 2083830230000000000000000ablack --keyring-backend $KEYRING
evmosd add-genesis-account $KEY2 2083830230000000000000000ablack --keyring-backend $KEYRING


# Update total supply with claim values
#validators_supply=$(cat $HOME/.evmosd/config/genesis.json | jq -r '.app_state["bank"]["supply"][0]["amount"]')
# Bc is required to add this big numbers
# total_supply=$(bc <<< "$amount_to_claim+$validators_supply")
# total_supply=1000000000000000000000000000
# cat $HOME/.evmosd/config/genesis.json | jq -r --arg total_supply "$total_supply" '.app_state["bank"]["supply"][0]["amount"]=$total_supply' > $HOME/.evmosd/config/tmp_genesis.json && mv $HOME/.evmosd/config/tmp_genesis.json $HOME/.evmosd/config/genesis.json


echo $KEYRING
echo $KEY
evmosd gentx $KEY2 2083830230000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID --ip 34.124.240.49
# Sign genesis transaction
# evmosd gentx $KEY2 2083830230000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID --ip 34.124.240.49
# evmosd gentx $KEY2 1000000000000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
# evmosd collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
# evmosd validate-genesis

# if [[ $1 == "pending" ]]; then
#   echo "pending mode is on, please wait for the first block committed."
# fi

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
# evmosd start --pruning=nothing --trace --log_level info --minimum-gas-prices=0.0001ablack --json-rpc.api eth,txpool,personal,net,debug,web3 --rpc.laddr "tcp://0.0.0.0:26657" --api.enable true

