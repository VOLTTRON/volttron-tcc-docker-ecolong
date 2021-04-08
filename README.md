# Prerequisites

* Docker version 20.10.5, build 55c4c88
* docker-compose version 1.28.5, build c4eb3a1f

# NOTES

* The volttron source code used is pinned to [`releases/8.x`](https://github.com/VOLTTRON/volttron/tree/releases/8.x)
* The docker image uses a minimal base image of Ubuntu 20.04 (focal)
* A pair of logs are created for each volttron instance. One log is dedicated to the platform configuration actions in core/setup-platform.py. That log is named <instance name>-<date>.log. It is stored in log/
  The other log captures all the log output when starting the volttron instance. That log is named <instance name>.volttron.log and is also stored in log/
* Logs for each container are stored in `log/`; Docker will mount log/ to store all log and database files. 
  This may require one to change permissions on that directory: chmod -R 777 log
* After running the docker containers, copy out the log files and database file from the log/ directory then delete the files. 
  Rerunning the dockers without doing this will concatenate the files with old runs.
* All services defined in docker-compose.yml use the same image. Therefore, docker-build will be used to build the image instead of docker-compose build, 
  which will build the image unnecessarily for each service defined in docker-compose.yml

# Quickstart
1. Initialize the submodules; for details see .gitmodules

```shell
$ git submodule update --init --recursive 
```

2. Build image and set name to "volttron/volttron:tcc"

```shell
$ docker build -t volttron/volttron:tcc .
```

3. Start container

```shell
$ docker-compose up
```

* If a container fails to start or stops, restart the starting of the containers. Follow the commands below:

```shell
$ docker-compose down
$ docker-compose up 
```

4. To view the logs of a service, enter inside the container and tail the logs. The command to tail the logs works 
   for all containers. Follow the example below:

```shell 
# Get inside building1 container
myuser@1234:~$ docker exec -itu volttron building1 bash
# tail the logs; commands works on all containers
volttron@building1:~$ tail -f $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log
```