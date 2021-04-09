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

echo "Setting up aliases for debugging."
echo "alias tlogs='tail -f $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
if [[ $(hostname) == "central" ]]; then
  {
  echo "alias grep-brsw='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/BRSW'"
  echo "alias grep-b1='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/BUILDING1'"
  echo "alias grep-so='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/SMALL_OFFICE'"
  echo "alias grep-lo='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/LargeOffice'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "brsw" ]]; then
  echo "alias grep-cmbr='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/BRSW'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "building1" ]]; then
  echo "alias grep-cmb1='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/BUILDING1'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "smalloffice" ]]; then
  echo "alias grep-cmso='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/SMALL_OFFICE'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "largeoffice" ]]; then
  echo "alias grep-cmlo='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/LargeOffice'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
fi
# shellcheck source=/home/volttron
source "${VOLTTRON_USER_HOME}/.bashrc"

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