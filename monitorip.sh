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

usage ()
{
	if [ $# -le 1 ]
	then
		echo "Usage: $(basename $0) [-u program_when_ip_comes_online] [-d program_when_ip_goes_offline] <hostname_or_IP_address>"
		exit 1
	fi
	exit 0
}

l2ping ()
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

l3ping ()
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
if [ $# -le 1 ]
then
	usage
	exit 1
fi

while [ $# -gt 1 ]
do
key="$1"

case $key in
    -u|--up)
    #echo up:$2
    ONLINE_CALL="$2"
    shift # past argument
    ;;
    -d|--down)
    #echo down:$2
    OFFLINE_CALL="$2"
    shift # past argument
    ;;
    --default)
    echo default $2
    DEFAULT=YES
    ;;
    *)
    usage
            # unknown option
    ;;
esac
shift # past argument or value
done
#echo $#
if [ $# -eq 0 ]
then
	usage
	exit 1
fi

# Check that these files exist are non zero and are executable
if ! [ -x $ONLINE_CALL ]
then
	echo Program ${ONLINE_CALL} must be an executable
	exit 1
fi

if ! [ -x $OFFLINE_CALL ]
then
	echo Program ${OFFLINE_CALL} must be an executable
	exit 1
fi
# all checks passed
# assign params
DEVICE=$1
# to bypass using sudo on rasp pi like devices do:
# sudo chmod u+s /usr/bin/arping
L2_CMD="arping $DEVICE -I $INTERFACE -c $HYSTERISIS -f -w $HYSTERISIS"
L3_CMD="ping $DEVICE -c 1 -w $HYSTERISIS"

# housekeeping - used internally
PINGRES=-1
PREVSTATE=0
#DEBUGLOG=/tmp/out
DEBUGLOG=/dev/null
#echo host is ${HOST}

# actual stuff begins now
while true
do
	l2ping
	#PINGRES=$?
	if [ $PINGRES -eq 0 ]; then
		#echo "$(date) : $DEVICE is on WLAN"
		#/usr/bin/mosquitto_pub -h localhost -t "home/hall/lights/power" -m "on"
		#echo calling $ONLINE_CALL
		$ONLINE_CALL

		if [ $PINGRES -ne $PREVSTATE ]; then
			echo -ne "\n$(date) : $DEVICE came online"
		else
			echo -n '!'
		fi
		sleep $AFTER_UP_DELAY
		#exit 0
	else
		#echo "$(date) : $DEVICE is off the WLAN"
		#/usr/bin/mosquitto_pub -h localhost -t "home/hall/lights/power" -m "off"
		#echo calling $OFFLINE_CALL
		$OFFLINE_CALL
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
