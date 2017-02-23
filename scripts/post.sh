#!/bin/bash

THEME=$1
CMD=$2

CONFIG=data/$THEME.config.toml

echo "Theme is $THEME"

if [[ $CMD == "new" ]]; then
	echo -n -e "input post name\n>> "
	read name
	hugo --config $CONFIG new post/$name.md
	exit $?
fi

if [[ $CMD == "del" ]]; then
	echo -n -e "input post name\n>> "
	read name
	rm -v content/post/$name.md
	exit $?
fi
