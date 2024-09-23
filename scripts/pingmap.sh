printf "PINGMAP V1.1"
printf "\nIP address of the host to be monitored: "
read IP

printf "\nPing interval (Press Enter for default 10 seconds): "
read delay
if [ -z "$delay" ]; then
    delay=10  # Default to 10 seconds if no input is provided
fi

printf "\nSave log file at (Press Enter to use current directory): "
read dir
if [ -z "$dir" ]; then
    dir=$(pwd)  # Use present working directory if no directory is provided
fi

current_date=$(date +"%Y-%m-%d")
printf "\nName of log file (Press Enter for default $current_date.log): "
read file
if [ -z "$file" ]; then
    file="$current_date.log"  # Default to current date as log file name
fi

touch "$dir/$file"

while true
do
    doot=$(date +"[%d/%b/%Y:%k:%M:%S %Z]")
    ping -i 0.01 -c 4 "$IP" > /dev/null
    if [ $? -eq 0 ]; then
        echo "$doot: $IP is up" >> "$dir/$file"
    else
        echo "$doot: $IP is down" >> "$dir/$file"
    fi
    echo "------" >> "$dir/$file"
    sleep "$delay"
done
