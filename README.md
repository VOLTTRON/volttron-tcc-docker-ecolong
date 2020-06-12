# VOLTTRON-tcc-docker
Repository containing the setup for TCC market agents.


Docker will mount log/ to store all log and database files.
This may require one to change permissions on that directory: chmod -R 777 log

Note:  After running TNS or ILC copy out the log files and database
file from the log/ directory then delete the files.  Rerunning the dockers
without doing this will concatenate the files with old runs.

# options for building building1, smalloffice, largeoffice, brsw, campus_city
make build building={building}

make run building={building}

# This will take you to VOLTTRON ENVIRONMENT
# For TNS/TCC you will need the city_campus and at least one building docker (in it's current configuration, you must run building1)

# Start the docker for building1 last as it triggers the building of the tns city agent, which inturn triggers the other paused simulations to proceed.  This will keep the E+ simulations  time in sync, if configured consistently.

# docker-compose was added for tns to simplify.
docker-compose build

docker-compose up