FROM ubuntu:latest 

# add your keyname
ARG KEY_NAME <add your keyname>

# add the nickname for your validator on the network
ARG MONIKER <add your moniker>

# add the network id
ARG NETWORK_ID black_9624-1

# arbitrary validator metadata
ARG DETAILS <details as string>

# add amount you're delegating
ARG TOKEN_DELEGATION <amount>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update &&\ 
	apt-get install -y apt-utils git git-extras software-properties-common vim \
	wget ca-certificates curl build-essential libssl-dev make openssh-server snap

RUN snap install go --classic

# builds out black
RUN git clone https://github.com/merlin-network/black-Testnet
WORKDIR /Black-Testnet/cmd/black
RUN go install -tags ledger ./... &&\
    mv $HOME/go/bin/black /usr/bin/

# generate keys
RUN black keys add $KEY_NAME
    # black keys add $KEY_NAME --recover &&\
    # black keys add $KEY_NAME --ledger 

# initialize node
RUN black init $MONIKER --chain-id black_9624-1

# get genesis file
RUN wget https://github.com/merlin-network/black-Testnet-v2/raw/main/genesis.json -P $HOME/.black/config/
RUN sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0001ablack"/g' $HOME/.black/config/app.toml
RUN wget https://github.com/merlin-network/black-Testnet-v2/raw/main/Docker/black.service -P $HOME/systemd/system/

# run black
WORKDIR /Black-Testnet/cmd/black
RUN sudo systemctl daemon-reload &&\
    sudo systemctl enable black.service &&\
    systemctl start black && journalctl -u black -f

ENTRYPOINT ["/bin/bash"]
