#!/bin/bash

THEME=$1
CMD=$2

CONFIG=data/$THEME.config.toml

echo "Theme is $THEME"

if [[ $CMD == "new" ]]; then
	echo -n -e "input category directory name\n>> "
	read dirname
	echo -n -e "input post name\n>> "
	read postname
	hugo --config $CONFIG new $dirname/$postname.md
	exit $?
fi
