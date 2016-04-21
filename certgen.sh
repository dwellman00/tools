#!/bin/bash
#
# *** MANAGED BY PUPPET - DO NOT EDIT DIRECTLY! ***
#
# Dale Wellman
# 7/2014
#
# Simple script to generate self signed certs

DOMAINS="$@"
if [ -z "$DOMAINS" ]; then
	echo "Usage: $(basename $0) <list of domains>"
	exit 11
fi

fail_if_error() {
	[ $1 != 0 ] && {
	unset PASSPHRASE
	exit 10
	}
}

for DOMAIN in $DOMAINS
do
	subj="
C=US
ST=California
O=Company
localityName=Temecula
commonName=$DOMAIN
organizationalUnitName=Information Technology
emailAddress=webmaster@company.com
"

	if [ ! -f $DOMAIN.key ]; then
		/usr/bin/openssl req -new -x509 -days 730 -nodes -subj "$(echo -n "$subj" | tr "\n" "/")" -newkey rsa:4096 -keyout $DOMAIN.key -out $DOMAIN.crt
	fi
done

# create domain list file for use by puppet
echo $DOMAINS > key_list

