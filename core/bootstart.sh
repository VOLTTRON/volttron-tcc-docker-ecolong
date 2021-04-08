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
volttron -vv -l /home/volttron/logs/$(hostname).volttron.log > /dev/null 2>&1 &
disown
sleep 10

# specific startup actions for each volttron instance
echo "Running additional startup actions for $(hostname)"
if [[ $(hostname) == "central" ]]; then
  vctl stop --tag forwarder
  sleep 300 # 5 minutes
  vctl restart --tag listener
  vctl restart --tag tns_campus tns_city
  vctl start --tag forwarder
else
  vctl restart --tag eplus forwarder listener
fi


# Last line of for CMD must be an infinite loop or else the container will automatically exit
while true; do sleep 15; done