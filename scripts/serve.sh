#!/bin/sh

BASEURL=http://ericnode.info
BIND=45.56.87.74
#BIND=127.0.0.1
HUGO=$HOME/bin/hugo 
SITEDIR=$HOME/ericnode
CONFIG=$SITEDIR/data/mainroad.config.toml
PORT=8080
FLAGS="--appendPort=false --disableLiveReload=true"

$HUGO server -ws $SITEDIR --config $CONFIG -p $PORT -b ${BASEURL} --bind ${BIND} $FLAGS
