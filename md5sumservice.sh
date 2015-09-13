# This is a helper script for WikiPland to compute md5sum
# using native code. Start this script before using tree.htm
# md5sum feature as follow:
# source treemd5sum.sh

# listener
# nc -l -p 20335
while true; do
echo Listening...
target=`nc -l -p 20336`
echo CMD:: md5sum $target
results="$(md5sum "$target")"
echo RST:: $results
echo $results | nc -l -p 20335
done
