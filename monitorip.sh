#!/bin/bash
#set -x
# Sample Usage
# monitorip.sh 192.168.1.5
#
##############################################################################
#  *****     Configuration parameters that need to be modified     *****
##############################################################################
AFTER_UP_DELAY=10
AFTER_DOWN_DELAY=3
INTERFACE=`/sbin/route -n | grep "^0.0.0.0" | awk {'print $8'}` # ex. wlan0

##############################################################################
# how many secs to wait before declaring device as down
##############################################################################
HYSTERISIS=5
# exit on Ctrl-C
trap "exit" INT
# Needs an IP to monitor on the network
if [ $# -ne 1 ]
then
	echo "Usage: $(basename $0) w.x.y.z"
	exit 1
fi
DEVICE=$1 
# to bypass using sudo on rasp pi like devices do:
# sudo chmod u+s /usr/bin/arping
L2_CMD="sudo arping $DEVICE -I $INTERFACE -c $HYSTERISIS -f -w $HYSTERISIS"
L3_CMD="ping $DEVICE -c 1 -w $HYSTERISIS"
# housekeeping - used internally
PINGRES=-1
PREVSTATE=0
#DEBUGLOG=/tmp/out
DEBUGLOG=/dev/null
function l2ping
{
		$L2_CMD >> $DEBUGLOG 2>&1
		#$L2_CMD >> /tmp/log 2>&1
		res=$?
		if [ $res -eq 0 ]; then
			#echo Success
		    	PINGRES=0
		else 
			# arping sometimes behaves strangely
			# be doubly sure its down
			# try a layer 3 ping
			l3ping
			if [ $res -eq 0 ]; then
				#echo Success
				PINGRES=0
			else	
				#echo Failure
				PINGRES=1
			fi	
		fi
}
function l3ping
{
		$L3_CMD >> $DEBUGLOG 2>&1
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
	l2ping
	#PINGRES=$?
	if [ $PINGRES -eq 0 ]; then
		#echo "$(date) : $DEVICE is on WLAN"
		/usr/bin/mosquitto_pub -h localhost -t "rohithall/power" -m "on"
		if [ $PINGRES -ne $PREVSTATE ]; then
			echo -ne "\n$(date) : $DEVICE came online"
		else
			echo -n '!'
		fi
		sleep $AFTER_UP_DELAY
		#exit 0
	else
		#echo "$(date) : $DEVICE is off the WLAN"
		/usr/bin/mosquitto_pub -h localhost -t "rohithall/power" -m "off"
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
