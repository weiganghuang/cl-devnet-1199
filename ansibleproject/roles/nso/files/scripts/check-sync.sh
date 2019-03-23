#!/bin/sh
echo "check sync status of device " $1
ncs_cli -u admin << EOF
request devices device $1 check-sync
exit
EOF
