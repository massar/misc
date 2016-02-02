#!/bin/bash

# Configure these to wanted values
CONTROLLER_HOSTNAME=[2001:db8::1]
CONTROLLER_REALHOSTNAME=controller.example.com
HTTP_HOSTNAME=www.example.com
EMPTYDIR=/www/empty
LOGNAME=/var/log/nginx/www.example.com-access.log

# Then run this script and it produces a new file

cp ubiquiti_video_proxy.conf custom_ubiquiti_video_proxy.conf
for i in CONTROLLER_HOSTNAME CONTROLLER_REALHOSTNAME HTTP_HOSTNAME EMPTYDIR LOGNAME;
do
	cat custom_ubiquiti_video_proxy.conf | sed "s#$i#${!i}#" >custom_ubiquiti_video_proxy.conf.new
	mv custom_ubiquiti_video_proxy.conf.new custom_ubiquiti_video_proxy.conf
done

exit 0

