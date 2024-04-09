#!/usr/bin/env bash

printf "PINGMAP V1.1"
printf "\nIP address of the host to be monitored: "
read IP
printf "\nPing interval: "
read delay
printf "\nSave log file at: "
read dir
printf "\nName of log file: "
read file
touch $dir/$file
while true
do
        doot=$(date +"[%d/%b/%Y:%k:%M:%S %Z]")
        ping -i 0.1 -c 4 "$IP" > /dev/null
        if [ $? -eq 0 ]; then
                echo "$doot: $IP is up" >> $dir/$file
        else
                echo "$doot: $IP is down" >> $dir/$file
        fi
        echo "------" >> $dir/$file
        sleep $delay
done
