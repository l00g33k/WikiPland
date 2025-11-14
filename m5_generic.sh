EXTRA=${EXTRA:-extra}
DTSTAMP=
DTSTAMP=${DTSTAMP:-$(date +'%Y%m%d_%H%M%S')}

DESC="_$(hostname)_$(whoami)_$(pwd|sed 's|/|_|g')_${EXTRA}"
OUTDIR=${OUTDIR:-$(pwd)}
echo "EXTRA=$EXTRA"
echo "OUTDIR=$OUTDIR"
echo "\"${OUTDIR}m5_${DTSTAMP}${DESC}.m5sz\""
# Comment this out for scripting
read -p "ENTER to continue"
echo "Output to: ${OUTDIR}m5_${DTSTAMP}${DESC}.m5sz"
pwd > "${OUTDIR}m5_${DTSTAMP}${DESC}.m5sz"
time find -name "*" -type f -print0 | xargs -0 stat -c "%s %n" >> "${OUTDIR}m5_${DTSTAMP}${DESC}.m5sz"
time find -name "*" -type f -print0 | xargs -0 md5sum >> "${OUTDIR}m5_${DTSTAMP}${DESC}.m5sz"
