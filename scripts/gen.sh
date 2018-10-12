#!/bin/bash

BASEURL=http://ericnode.info
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
SITEDIR=`realpath -e $SCRIPTPATH/..`
CONFIG="$SITEDIR/data/mainroad.config.toml"
PORT=1313
FLAGS="--disableLiveReload=true --appendPort=false"

TEMP=$SITEDIR/generated

IN="$SITEDIR/scripts/hugo.service.in"
OUT="$TEMP/hugo.service"
SED_SCRIPT="$TEMP/sed_web.sh"

IN_UP="$SITEDIR/scripts/hugo-update.service.in"
OUT_UP="$TEMP/hugo-update.service"
SED_UPDATE="$TEMP/sed_update.sh"

mkdir -p $TEMP

echo "#!/bin/bash" > $SED_SCRIPT
echo "sed '/^ExecStart/s,SITEDIR,"${SITEDIR}",' $IN > $OUT" >> $SED_SCRIPT
echo "sed -i '/^ExecStart/s,CONFIG,"${CONFIG}",' $OUT" >> $SED_SCRIPT
echo "sed -i '/^ExecStart/s,PORT,"${PORT}",' $OUT" >> $SED_SCRIPT
echo "sed -i '/^ExecStart/s,BASEURL,"${BASEURL}",' $OUT" >> $SED_SCRIPT
echo "sed -i '/^ExecStart/s,FLAGS,"${FLAGS}",' $OUT" >> $SED_SCRIPT
chmod +x $SED_SCRIPT
$SED_SCRIPT

echo "#!/bin/bash" > $SED_UPDATE
echo "sed 's,SITEDIR,"${SITEDIR}",' $IN_UP > $OUT_UP" >> $SED_UPDATE
chmod +x $SED_UPDATE
$SED_UPDATE
