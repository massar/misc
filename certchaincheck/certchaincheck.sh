#!/bin/sh

# certchaincheck -- https://github.com/massar/misc/certchaincheck/

if [ $# -ne 2 ];
then
	echo "Usage: certchaincheck <host> <port>"
	exit 1
fi

HOST=$1
PORT=$2

ret=0

out=$(openssl s_client -showcerts -connect ${HOST}:${PORT} </dev/null 2>/dev/null)

collect="no"

printf '%s\n' "$out" | while IFS= read -r line
do
	case "${line}" in
		"-----BEGIN CERTIFICATE-----")
			cert="${line}\n"
			collect="yes"
			;;
		"-----END CERTIFICATE-----")
			cert="${cert}${line}\n"
			echo "---------------- Certificate"
			IFS=" "
			out=$(echo ${cert} | openssl x509 -noout -text | grep -iE "(Signature Algo)|Issuer:|Subject:")
			echo $out
			echo $out | grep "sha1WithRSAEncryption" >/dev/null 2>/dev/null
			if [ $? -eq 0 ];
			then
				echo ">>>>>>>>>>>>>>>>>>>>>>> CERTIFICATE HAS SHA1 SIGNATURES <<<<<<<<<<<<<<<<<<<<<<"
				ret=2
			fi
			collect="no"
			;;
		*)
			if [ $collect = "yes" ];
			then
				cert="${cert}${line}\n"
			fi
			;;
	esac
done

echo "---------------- Done"
exit ${ret}

