#!/bin/sh
echo "check sync status of device " $1
ncs_cli -u admin << EOF
 request devices device master config unix-bind:EXEC exec args "sudo -u cl94644 /bin/python /tmp/$2/syncdns/syncdns.py -h"
exit
EOF
