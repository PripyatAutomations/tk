Put your firmwares into www/cisco/firmwares/ (firmwares/cisco-voip/)

Your phone should automatically update and pull its configuration via http.

In your DHCP, you probably should be giving options 66 and 110 with the IP
of this host.

option 66,10.1.2.3
option 110,10.1.2.3


That will tell your phone where to boot.

We don't want to tftp the firmware to the phone as it's too slow. It will
try TFTP then HTTP, so don't place the firmware in tftp too!
