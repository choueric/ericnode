#!/bin/bash

BASEURL=http://ericnode.info
BIND=ericnode.info
#BIND=127.0.0.1
HUGO=$HOME/bin/hugo 
SITEDIR=$HOME/ericnode
CONFIG=$SITEDIR/data/mainroad.config.toml
PORT=80
FLAGS="--disableLiveReload=true"

if [[ $1 == "test" ]]; then
	$HUGO server -ws $SITEDIR --config $CONFIG \
		--buildDrafts -b http://localhost
fi

$HUGO server -ws $SITEDIR --config $CONFIG \
	-p $PORT -b ${BASEURL} --bind ${BIND} $FLAGS
