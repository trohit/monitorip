# monitorip
Simple BASH script that monitors whenever a device with a static IP joins or leaves the network

# Sample Usage and Output
monitorip.sh 192.168.1.5   
!!  
Mon 11 Jul 17:58:03 IST 2016 : 192.168.1.5 went offline.  
Mon 11 Jul 17:58:21 IST 2016 : 192.168.1.5 came online!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
Mon 11 Jul 18:08:51 IST 2016 : 192.168.1.5 went offline............   
Mon 11 Jul 18:11:30 IST 2016 : 192.168.1.5 came online  

# Use:
Can be used to control a sonoff(ESP 8266)   
eg. switch lights on when mobile phone/laptop is detected in wifi zone and switch off when device leaves the wifi.

ESP 8266 can be loaded with loaded with 

1. lua firmware from https://github.com/elric91/nodemcu_sonoff

OR 

2. alternative firmware from https://bitbucket.org/xoseperez/espurna
