#!/bin/sh

BASEURL=http://ericnode.info
BIND=45.56.87.74
#BIND=127.0.0.1
HUGO=$HOME/bin/hugo 
SITEDIR=$HOME/ericnode
CONFIG=$SITEDIR/config.toml
PORT=8080

$HUGO server -w --config $CONFIG -p $PORT -b ${BASEURL} --bind ${BIND} -s $DIR
