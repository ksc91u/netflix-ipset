# netflix-ipset
A simple tutorial of how to route netflix traffic to ISP, while other traffic can be routed to VPN. On EdgeRouter or other Linux routers supports IPSet.

## Daily Updated IPSet file
[https://nflx.ksc91u.info/as-nflx](https://nflx.ksc91u.info/as-nflx)

If you have trouble restore from this file, try with ```-exist``` flag ```/sbin/ipset -exist restore < as-nflx```

## Netflix AS40027, AS2906
You can find netflix AS on [bgpview.io](https://bgpview.io/search/netflix). Download all prefixes with [bgpview api](https://bgpview.docs.apiary.io/#reference/0/asn-prefixes/view-asn-prefixes).  

[https://api.bgpview.io/asn/40027/prefixes](https://api.bgpview.io/asn/40027/prefixes)

Or use [ASAllow](https://github.com/42wim/asallow) to generate ipset files. 

### asallow.conf

```
[main]
#prefixes of providers which should be looked up dynamically (using ripestat)
ASN=AS40027 #netflix
ASN=AS2906 #netflix streaming
nocomment #output nocomment or edgerouter won't restore it.
```

The output file will look like

```
create AS_nflx hash:net family inet hashsize 1024 maxelem 65536
add AS_nflx 192.173.92.0/24
add AS_nflx 23.246.6.0/24
add AS_nflx 192.173.67.0/24
add AS_nflx 198.38.121.0/24
```

Remove the first line, and scp file to edgerouter ```ubnt@ubnt:/config/user-data/as-nflx```

Next, create a **Network Group** on EdgeRouter GUI called **AS_nflx**.

## Script to update ipset periodically

#### File /config/user-data/netflix
List of netflix API servers

```
www.us-east-1.internal.dradis.netflix.com.
www.us-east-2.internal.dradis.netflix.com.
www.us-west-1.internal.dradis.netflix.com.
www.us-west-2.internal.dradis.netflix.com.
www.eu-west-1.internal.dradis.netflix.com.
prod.http1.us-west-1.internal.dradis.netflix.com.
prod.http1.us-west-2.internal.dradis.netflix.com.
prod.http1.us-east-1.internal.dradis.netflix.com.
prod.http1.us-east-2.internal.dradis.netflix.com.
prod.http1.eu-west-1.internal.dradis.netflix.com.
mobile.prod.us-west-1.internal.dradis.netflix.com.
mobile.prod.us-west-2.internal.dradis.netflix.com.
mobile.prod.us-east-1.internal.dradis.netflix.com.
mobile.prod.us-east-2.internal.dradis.netflix.com.
mobile.prod.eu-west-1.internal.dradis.netflix.com.
www.netflix.com
netflix.com
```
#### File /config/user-data/update-nflx.sh
```
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
```

Then cronjob with root ```sudo crontab -e ```

```
*/20 * * * * /config/user-data/update-nflx.sh
```

## Rule based routing

Now you can use network group AS_nflx for rule based routing.
Take part of my config for example.

Traffic to netflix will go through lb-group G, which is my group of 4 pppoe connections. Other traffic will go to lb-group VPN_OUT.

```
rule 70 {
            action modify
            destination {
                group {
                    network-group AS_nflx
                }
            }
            modify {
                lb-group G
            }
            source {
                address 192.168.1.64/26
            }
        }
rule 71 {
            action modify
            destination {
                group {
                    network-group !AS_nflx
                }
            }
            modify {
                lb-group VPN_OUT
            }
            source {
                address 192.168.1.64/26
            }
        }
```

## Other things
Netflix hosts API servers in US and Europe only, those CNAMES are what I found with [DNSChecker](https://dnschecker.org/), a global DNS lookup tools. The mobile-* CNAMES are requested by Windows 10 Netflix App, observed with tcpdump on udp port 53.

If more host names/IP blocks should be added, need DNSMasq to log all queries. But this is sufficient for me now.




