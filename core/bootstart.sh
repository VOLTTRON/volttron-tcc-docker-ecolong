#! /usr/bin/env bash

# We are going to pre-setup the platform before running any of the environment.
if [[ -z /startup/setup-platform.py ]]; then
    echo "/startup/setup-platform.py does not exist.  The docker image must be corrupted"
    exit 1
fi

echo "Right before setup-platform.py is called I am calling printenv"
printenv

python3 /startup/setup-platform.py
setup_return=$?

if [[ $setup_return -ne 0 ]]; then
    echo "error running setup-platform.py"
    exit $setup_return
fi

echo "Setup of Volttron platform is complete."
echo "Starting Volttron for container: $(hostname)........."
mkdir -p /home/volttron/volttron/log
volttron -vv -l /home/volttron/volttron/log/volttron.log > /dev/null 2>&1&
disown
sleep 5

# specific startup actions for each volttron instance
echo "Running additional startup actions for $(hostname)"
if [[ $(hostname) == "central" ]]; then
  sleep 60
  vctl start --tag forwarder listener sqlite-db tns_campus
#  while : ;do
#    [[ -f "/home/volttron/volttron/log/volttron.log" ]] && grep -q "devices/PNNL/BUILDING1/AHU2/all" "/home/volttron/volttron/log/tns.log" && echo "FOUND" && break
#    sleep 5
#  done
#  vctl start --tag tns_city
elif [[ $(hostname) == "building1" ]]; then
  echo "Starting agents..."
  vctl start --tag listener vav ahu eplus light market-service sqlite-db tns_building uncontrol_load forwarder
fi


# Last line of for CMD must be an infinite loop or else the container will automatically exit
while true; do sleep 15; done