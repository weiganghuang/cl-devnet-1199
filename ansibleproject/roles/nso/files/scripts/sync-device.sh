#!/bin/sh
echo "sync device" $1
ncs_cli -u admin << EOF
request devices device $1 sync-from
exit
EOF
