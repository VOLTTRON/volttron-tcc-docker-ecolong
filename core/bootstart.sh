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

LOG_FILE=$VOLTTRON_USER_HOME/logs/$(hostname)-$(date +"%FT%T").volttron.log

echo "Setting up aliases for debugging."
{
  echo "alias tlogs='tail -f $LOG_FILE'"
  echo "alias tlogsERROR='tail -f $LOG_FILE | grep ERROR -a'"
  echo "alias grep-ERROR='cat $LOG_FILE | grep ERROR -a'"
  echo "alias grep-error='cat $LOG_FILE | grep error -a'"
  echo "alias grep-cycle='cat $LOG_FILE | grep start_new_cycle -a'"
} >> "$VOLTTRON_USER_HOME/.bash_aliases"

echo "export VLOG='$LOG_FILE'" >> .bashrc

if [[ $(hostname) == "central" ]]; then
  {
  # The search string for 'grep' are based on the custom topic of each service's forwarder configuration
  # For example, for the BRSW container, 'tnc/BRSW' is a custom topic defined in BRSW's forwarder configuration key 'custom_topic_list',
  # the config file for BRSW is located at ~<repo_root>/platform_configs/brsw/agent_configs/forwarder.config
  echo "alias grep-brsw='cat $LOG_FILE | grep tnc/BRSW -a'"
  echo "alias grep-b1='cat $LOG_FILE | grep tnc/BUILDING1 -a'"
  echo "alias grep-so='cat $LOG_FILE | grep tnc/SMALL_OFFICE -a'"
  echo "alias grep-lo='cat $LOG_FILE | grep tnc/LargeOffice -a'"
  echo "alias vrestart='vctl start --tag tns*  sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "brsw" ]]; then
  {
  echo "alias grep-cmbr='cat $LOG_FILE | grep tnc/campus/BRSW -a'"
  echo "alias vrestart='vctl start --tag rtu tns* market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "building1" ]]; then
  {
  echo "alias grep-cmb1='cat $LOG_FILE | grep tnc/campus/BUILDING1 -a'"
  echo "alias vrestart='vctl start --tag vav ahu light uncontrol_load tns* market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "smalloffice" ]]; then
  {
  echo "alias grep-cmso='cat $LOG_FILE | grep tnc/campus/SMALL_OFFICE -a'"
  echo "alias vrestart='vctl start --tag rtu tns* light market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
elif [[ $(hostname) == "largeoffice" ]]; then
  {
  echo "alias grep-cmlo='cat $LOG_FILE | grep tnc/campus/LargeOffice -a'"
  echo "alias vrestart='vctl start --tag vav ahu light uncontrol_load tns* market-service sqlite-db forwarder listener'"
  } >> "$VOLTTRON_USER_HOME/.bash_aliases"
fi

echo "Starting Volttron for container: $(hostname)"
# the command below will ensure that logs are written and persisted; these logs will persist in a folder on the host machine
# thus ensuring that logs will not be lost when the container is removed
volttron -vv -l "$LOG_FILE" > /dev/null 2>&1 &
disown
sleep 10

# specific startup actions for each volttron instance
echo "Running additional startup actions for container: $(hostname)"
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

echo "Startup actions completed for container $(hostname)"

# Last line for CMD must be an infinite loop or else the container will automatically exit
while true; do sleep 15; done
