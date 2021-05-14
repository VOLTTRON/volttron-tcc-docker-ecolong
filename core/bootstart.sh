#! /usr/bin/env bash

# We are going to pre-setup the platform before running any of the environment.
if [[ -z /startup/setup-platform.py ]]; then
    echo "/startup/setup-platform.py does not exist. The docker image must be corrupted"
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
  # The search string for 'grep' are based on the custom topic of each service's forwarder configuration
  # For example, for the BRSW container, 'tnc/BRSW' is a custom topic defined in BRSW's forwarder configuration key 'custom_topic_list',
  # the config file for BRSW is located at ~<repo_root>/platform_configs/brsw/agent_configs/forwarder.config
  echo "alias grep-brsw='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/BRSW'"
  echo "alias grep-b1='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/BUILDING1'"
  echo "alias grep-so='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/SMALL_OFFICE'"
  echo "alias grep-lo='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/LargeOffice'"
  echo "alias vrestart='vctl start --tag tns*  sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "brsw" ]]; then
  {
  echo "alias grep-cmbr='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/BRSW'" 
  echo "alias vrestart='vctl start --tag rtu tns* market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "building1" ]]; then
  
  { 
  echo "alias grep-cmb1='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/BUILDING1'"
  echo "alias vrestart='vctl start --tag vav ahu light uncontrol_load tns* market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "smalloffice" ]]; then
  {
  echo "alias grep-cmso='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/SMALL_OFFICE'" 
  echo "alias vrestart='vctl start --tag rtu tns* light market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "largeoffice" ]]; then
  {
  echo "alias grep-cmlo='cat $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log | grep tnc/campus/LargeOffice'" 
  echo "alias vrestart='vctl start --tag vav ahu light uncontrol_load tns* market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
fi

echo "Starting Volttron for container: $(hostname)."
volttron -vv -l /home/volttron/logs/$(hostname).volttron.log > /dev/null 2>&1 &
disown
sleep 10

# specific startup actions for each volttron instance
echo "Running additional startup actions for $(hostname)"
if [[ $(hostname) == "central" ]]; then
  sleep 300 # 5 minutes
  vctl start --tag sqlite-db listener tns_campus tns_city
  vctl start --tag forwarder
elif [[ $(hostname) == "brsw" ]]; then
  vctl start --tag eplus
  sleep 25
  vctl start --tag rtu uncontrol_load market-service sqlite-db listener tns_building
  vctl start --tag forwarder
elif [[ $(hostname) == "building1" ]]; then
  vctl start --tag eplus
  sleep 40
  vctl start --tag ahu vav light uncontrol_load market-service sqlite-db listener tns_building
  vctl start --tag forwarder
elif [[ $(hostname) == "smalloffice" ]]; then
  vctl start --tag eplus
  sleep 25
  vctl start --tag rtu light uncontrol_load market-service sqlite-db listener tns_building
  vctl start --tag forwarder
elif [[ $(hostname) == "largeoffice" ]]; then
  vctl start --tag eplus
  sleep 16
  vctl start --tag ahu vav light uncontrol_load market-service sqlite-db listener tns_building
  vctl start --tag forwarder
fi

# Last line of for CMD must be an infinite loop or else the container will automatically exit
while true; do sleep 15; done
