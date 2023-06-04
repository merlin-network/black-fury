# GENTX & HARDFORK INSTRUCTIONS

### Install & Initialize 

* Install black binary

* Initialize black node directory 
```bash
black init <node_name> --chain-id <chain_id>
```
### Add a Genesis Account
A genesis account is required to create a GENTX

```bash
black add-genesis-account <address-or-key-name> afury --chain-id <chain-id>
```
### Create & Submit a GENTX file + genesis.json
A GENTX is a genesis transaction that adds a validator node to the genesis file.
```bash
black gentx <key_name> <token-amount>afury --chain-id=<chain_id> --moniker=<your_moniker> --commission-max-change-rate=0.01 --commission-max-rate=0.10 --commission-rate=0.05 --details="<details here>" --security-contact="<email>" --website="<website>"
```
* Fork [Black](https://github.com/merlin-network/black)

* Copy the contents of `${HOME}/.black/config/gentx/gentx-XXXXXXXX.json` to `$HOME/black-fury/Mainnet/gentx/<yourvalidatorname>.json`

* Copy the genesis.json file `${HOME}/.black/config/genesis.json` to `$HOME/Black/Mainnet/Genesis-Files/`

* Create a pull request to the main branch of the [repository](https://github.com/merlin-network/black/Mainnet/gentx)

### Restarting Your Node

You do not need to reinitialize your Black Node. Basically a hard fork on Cosmos is starting from block 1 with a new genesis file. All your configuration files can stay the same. Steps to ensure a safe restart

1) Backup your data directory. 
* `mkdir $HOME/black-backup` 

* `cp $HOME/.black/data $HOME/black-backup/`

2) Remove old genesis 

* `rm $HOME/.black/genesis.json`

3) Download new genesis

* `wget`

4) Remove old data

* `rm -rf $HOME/.black/data`

5) Create a new data directory

* `mkdir $HOME/.black/data`

If you do not reinitialize then your peer id and ip address will remain the same which will prevent you from needing to update your peers list.

7) Download the new binary
```
cd $HOME/Black
git checkout <branch>
make install
mv $HOME/go/bin/black /usr/bin/
```


6) Restart your node

* `systemctl restart black`

## Emergency Reversion

1) Move your backup data directory into your .black directory 

* `mv HOME/black-backup/data $HOME/.black/`

2) Download the old genesis file

* `wget https://github.com/merlin-network/black/raw/main/Mainnet/genesis.json -b $HOME/.black/config/`

3) Restart your node

* `systemctl restart black`