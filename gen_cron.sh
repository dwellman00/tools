#!/bin/bash
#
# *** MANAGED BY PUPPET - DO NOT EDIT DIRECTLY! ***
#
# Dale Wellman
# 10/18/2014
#
# Wrapper script to run from cron
#

# Set to echo for debug
DEBUG=

TOOLSDIR=/data/tools

# Phone list
$DEBUG $TOOLSDIR/gen_phonelist.pl

# generate hardware wiki pages from racktables db
#    arguments are:
#	-i tag id to search db for
#	-T name of wiki page to update
#	-t name of wiki section to update
#	-s wiki section number to update

# Server Hardware
$DEBUG $TOOLSDIR/gen_hardware.pl -i oraclesrv -T Server_Hardware -t "Oracle Server List" -s 1
$DEBUG $TOOLSDIR/gen_hardware.pl -i hpsrv -T Server_Hardware -t "HP Server List" -s 2
$DEBUG $TOOLSDIR/gen_hardware.pl -i dellsrv -T Server_Hardware -t "Dell Server List" -s 3

# Network Hardware
$DEBUG $TOOLSDIR/gen_hardware.pl -i cisco -T Network_Hardware -t "Cisco Hardware" -s 1
$DEBUG $TOOLSDIR/gen_hardware.pl -i arista -T Network_Hardware -t "Arista Hardware" -s 2
$DEBUG $TOOLSDIR/gen_hardware.pl -i firewall -T Network_Hardware -t "Firewall Hardware" -s 3
$DEBUG $TOOLSDIR/gen_hardware.pl -i riverbed -T Network_Hardware -t "Riverbed Hardware" -s 4
$DEBUG $TOOLSDIR/gen_hardware.pl -i networking -T Network_Hardware -t "Misc Hardware" -s 5

# Storage Hardware
$DEBUG $TOOLSDIR/gen_hardware.pl -i netapp -T Storage_Hardware -t "Netapp Hardware" -s 1
$DEBUG $TOOLSDIR/gen_hardware.pl -i nimble -T Storage_Hardware -t "Nimble Hardware" -s 2
$DEBUG $TOOLSDIR/gen_hardware.pl -i oraclestr -T Storage_Hardware -t "Oracle Storage Hardware" -s 3
$DEBUG $TOOLSDIR/gen_hardware.pl -i hpstr -T Storage_Hardware -t "HP Storage Hardware" -s 4
$DEBUG $TOOLSDIR/gen_hardware.pl -i tapelib -T Storage_Hardware -t "Tape Library Hardware" -s 5

# Wireless Hardware
$DEBUG $TOOLSDIR/gen_hardware.pl -i aruba -T Wireless_Hardware -t "Aruba Hardware" -s 1
$DEBUG $TOOLSDIR/gen_hardware.pl -i engenius -T Wireless_Hardware -t "EnGenius Hardware" -s 2

# Printers
$DEBUG $TOOLSDIR/gen_hardware.pl -i canon -T Printers -t "Canon Printers" -s 2
$DEBUG $TOOLSDIR/gen_hardware.pl -i hpprt -T Printers -t "HP Printers" -s 3
$DEBUG $TOOLSDIR/gen_hardware.pl -i dellprt -T Printers -t "Dell Printers" -s 4
$DEBUG $TOOLSDIR/gen_hardware.pl -i samsung -T Printers -t "Samsung Printers" -s 5
$DEBUG $TOOLSDIR/gen_hardware.pl -i printek -T Printers -t "Printek Printers" -s 6
$DEBUG $TOOLSDIR/gen_hardware.pl -i zebra -T Printers -t "Zebra Printers" -s 7
