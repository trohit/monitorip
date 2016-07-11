#!/bin/bash
# Sample Usage
# monitorip.sh 192.168.1.5
#

##############################################################################
#  *****     Configuration parameters that need to be modified     *****
##############################################################################
AFTER_UP_DELAY=10
AFTER_DOWN_DELAY=3
DEVICE=$1 
INTERFACE=wlp3s0
##############################################################################
# how many secs to wait before declaring device as down
##############################################################################
HYSTERISIS=10
CMD="arping $DEVICE -I $INTERFACE -c $HYSTERISIS -f -w $HYSTERISIS"

# housekeeping - used internally
PINGRES=0
PREVSTATE=0


# exit on Ctrl-C
trap "exit" INT

# Needs an IP to monitor on the network
if [ $# -ne 1 ]
then
	echo "Usage: $(basename $0) w.x.y.z"
	exit 1
fi

function ping_dev
{
		$CMD > /dev/null 2>&1
		#$CMD >> /tmp/log 2>&1
		res=$?
		if [ $res -eq 0 ]; then
			#echo Success
		    PINGRES=0
		else 
			#echo Failure
			PINGRES=1
		fi
}

# main
while true
do
	#CMD="./checkfordev.sh $DEVICE"
	#$CMD
	ping_dev
	#PINGRES=$?
	if [ $PINGRES -eq 0 ]; then
		#echo "$(date) : $DEVICE is on WLAN"
		if [ $PINGRES -ne $PREVSTATE ]; then
			echo -ne "\n$(date) : $DEVICE came online"
		else
			echo -n '!'
		fi
		sleep $AFTER_UP_DELAY
		#exit 0
	else
		#echo "$(date) : $DEVICE is off the WLAN"
		if [ $PINGRES -ne $PREVSTATE ]; then
			echo -ne "\n$(date) : $DEVICE went offline"
		else
			echo -n '.'
		fi
		sleep $AFTER_DOWN_DELAY
		#exit 1
    fi
	PREVSTATE=$PINGRES
	
	#sleep $DELAY
done
