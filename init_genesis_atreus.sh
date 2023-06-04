KEY="atreus"
CHAINID="highbury_710-1"
MONIKER="atreus"
KEYRING="os"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# to trace evm
#TRACE="--trace"
TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# Reinstall daemon
rm -rf ~/.black*
make install

# Set client config
black config keyring-backend $KEYRING
black config chain-id $CHAINID

# if $KEY exists it should be deleted
black keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for Black (Moniker can be anything, chain-id must be an integer)
black init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to ablack
cat $HOME/.black/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["evm"]["params"]["evm_denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["inflation"]["params"]["mint_denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json

# Change voting params so that submitted proposals pass immediately for testing
cat $HOME/.black/config/genesis.json| jq '.app_state.gov.voting_params.voting_period="7200s"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json

# disable produce empty block
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.black/config/config.toml
  else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.black/config/config.toml
fi

if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.black/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.black/config/config.toml
  fi
fi



# Allocate genesis accounts (cosmos formatted addresses)
black add-genesis-account $KEY 851201264446789000000000000ablack --keyring-backend $KEYRING

echo $KEYRING
echo $KEY
# Sign genesis transaction
black gentx $KEY 100000000000000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID --ip 35.200.104.35
#black gentx $KEY2 1000000000000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
black collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
black validate-genesis

if [[ $1 == "pending" ]]; then
  echo "pending mode is on, please wait for the first block committed."
fi

mv $HOME/.black/config/gentx $HOME/black-fury/Mainnet/gentx-atreus
mv $HOME/.black/config/genesis.json $HOME/black-fury/Mainnet/genesis-atreus.json

git config --global user.email adrian@fury.fan
git config --global user.name adrian

git add .
git commit -am "gentx"
git push 

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
# black start --pruning=nothing --trace --log_level info --minimum-gas-prices=0.0001ablack --json-rpc.api eth,txpool,personal,net,debug,web3 --rpc.laddr "tcp://0.0.0.0:26657" --api.enable true

