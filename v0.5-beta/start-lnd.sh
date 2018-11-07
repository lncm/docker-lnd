#!/usr/bin/env bash

# exit from script if error was raised.
set -e

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit.
error() {
    echo "$1" > /dev/stderr
    exit 0
}

# return is used within bash function in order to return the value.
return() {
    echo "$1"
}

# set_default function gives the ability to move the setting of default
# env variable from docker file to the script thereby giving the ability to the
# user override it durin container start.
set_default() {
    # docker initialized env variables with blank string and we can't just
    # use -z flag as usually.
    BLANK_STRING='""'

    VARIABLE="$1"
    DEFAULT="$2"

    if [[ -z "$VARIABLE" || "$VARIABLE" == "$BLANK_STRING" ]]; then

        if [ -z "$DEFAULT" ]; then
            error "You should specify default variable"
        else
            VARIABLE="$DEFAULT"
        fi
    fi

   return "$VARIABLE"
}

# Set default variables if needed.
ALIAS=$(set_default "$ALIAS" "#lncmreckless")
RPCUSER=$(set_default "$RPCUSER" "devuser")
RPCPASS=$(set_default "$RPCPASS" "devpass")
RPCHOST=$(set_default "$RPCHOST" "localhost")
# -zmqpubrawblock=tcp://0.0.0.0:28332", "-zmqpubrawtx=tcp://0.0.0.0:28333
ZMQPUBRAWBLOCK=$(set_default "$ZMQPUBRAWBLOCK" "127.0.0.1:28332")
ZMQPUBRAWTX=$(set_default "$ZMQPUBRAWTX" "127.0.0.1:28333")

DEBUG=$(set_default "$DEBUG" "debug")
NETWORK=$(set_default "$NETWORK" "mainnet")
CHAIN=$(set_default "$CHAIN" "bitcoin")
BACKEND="bitcoind"
if [[ "$CHAIN" == "litecoin" ]]; then
    BACKEND="ltcd"
fi

exec lnd \
    --noseedbackup \
    --lnddir="/lnd" \
    --configfile="/lnd/lnd.conf" \
    --logdir="/data" \
    "--alias=$ALIAS" \
    "--$CHAIN.active" \
    "--$CHAIN.$NETWORK" \
    "--$CHAIN.node"="bitcoind" \
    "--$BACKEND.rpchost"="$RPCHOST" \
    "--$BACKEND.rpcuser"="$RPCUSER" \
    "--$BACKEND.rpcpass"="$RPCPASS" \
    "--bitcoind.zmqpubrawblock=tcp://$ZMQPUBRAWBLOCK" \
    "--bitcoind.zmqpubrawtx=tcp://$ZMQPUBRAWTX" \
    "--rpclisten=0.0.0.0:10009" \
    "--rpclisten=127.0.0.1:10008" \
    "--restlisten=0.0.0.0:8080" \
    "--listen=0.0.0.0:10008" \
    --debuglevel="$DEBUG" \
    "$@"
