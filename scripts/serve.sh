#!/bin/bash

BASEURL=http://ericnode.info
BIND=45.56.87.74
#BIND=127.0.0.1
HUGO=/home/zhs/bin/hugo 
SITEDIR=/home/zhs/ericnode
CONFIG=$SITEDIR/data/mainroad.config.toml
PORT=80
FLAGS="--disableLiveReload=true"

if [[ $1 == "test" ]]; then
	hugo server -ws $SITEDIR --config $CONFIG \
		--buildDrafts -b http://localhost
fi

$HUGO server -ws $SITEDIR --config $CONFIG \
	-p $PORT -b ${BASEURL} --bind ${BIND} $FLAGS
