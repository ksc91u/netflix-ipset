#!/bin/bash
/sbin/ipset -exist restore </config/user-data/as-nflx
for n in `cat /config/user-data/netflix`
do
        for i in `host $n|grep IPv4|cut -d " " -f 5 `
        do
                echo "Add nflx $i"
                /sbin/ipset add AS_nflx $i 2>/dev/null
        done
done
