#!/bin/bash

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
SITEDIR=`realpath -e $SCRIPTPATH/..`

cd $SITEDIR; git pull
cd themes/mainroad; git pull
