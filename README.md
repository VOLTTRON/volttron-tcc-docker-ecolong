# Prerequisites

* Docker version 20.10.5, build 55c4c88
* docker-compose version 1.28.5, build c4eb3a1f

# Notes

## Git Submodules
* The volttron submodule is pinned to [`releases/8.x`](https://github.com/VOLTTRON/volttron/tree/releases/8.x)
* The volttron-GS submodule is pinned to [`main`](https://https://github.com/VOLTTRON/volttron-GS/tree/main)
* Over time, the commits on the aforementioned submodules can change. To ensure that you get the latest commits for those submodules, run the following command: ```git submodule update --remote --merge``` This command will fetch the latest changes from upstream in each submodule, merge them in, and check out the latest revision of the submodule.

## Docker
* The docker image uses a minimal base image of Ubuntu 20.04 (focal)
* A pair of logs are created for each volttron instance. One log is dedicated to the platform configuration actions in core/setup-platform.py. That log is named <instance name>-<date>.log. It is stored in log/
  The other log captures all the log output when starting the volttron instance. That log is named <instance name>.volttron.log and is also stored in log/
* Logs for each container are stored in `log/`; Docker will mount log/ to store all log and database files. 
  This may require one to change permissions on that directory: chmod -R 777 log
* After running the docker containers, copy the "<instance name>.volttron.log" files from the log/ directory then delete the files. 
  Rerunning the dockers without doing this will overwrite these log files.   
* Unlike the "<instance name>.volttron.log" log files, the logs for the setup-platform.py script (i.e. "<instance name>-<date>.log") will not be overwritten when rerunning docker-compose. Instead, new logs are generated when rerunning the docker containers. 
* All services defined in docker-compose.yml use the same image. Therefore, docker-build will be used to build the image instead of docker-compose build, 
  which will build the image unnecessarily for each service defined in docker-compose.yml

# Quickstart
1. Initialize the submodules; for details see .gitmodules

```shell
$ git submodule update --init --recursive 
```

2. Build image and start container

```shell
# build the image without using cache
$ docker-compose build --no-cache  --force-rm
$ docker-compose up
```


3. To view the logs of a service, enter inside the container and tail the logs. The command to tail the logs works 
   for all containers. Follow the example below:

```shell 
# Get inside building1 container
myuser@1234:~$ docker exec -itu volttron building1 bash
# tail the logs; commands works on all containers
volttron@building1:~$ tail -f $VOLTTRON_USER_HOME/logs/$(hostname).volttron.log
```

NOTE: Aliases have been added to the containers for convenience. See 'Aliases in the container' section for more details.

## Container info

All containers are explicitly named in docker-compose.yml; specifically, each service defined in docker-compose.yml has a 'container_name' section. Thus, you can easily enter into a container via a human-readable container name. 
For example, to enter into the Volttron central instance, use ```docker-compose exec -itu volttron central bash```.  

In addition, the hostnames for the containers have also been explicitly defined in docker-compose.yml; each service has a `hostname` section. With this configuration, you know exactly which container you are in; this is helpful when opening several shells to monitor several buildings.
For example:

```shell
# shell1
$ docker-compose exec -itu volttron central bash
volttron@central:~$

# shell2
$ docker-compose exec -itu volttron building1 bash
volttron@building1:~$
```

## Aliases in the container

Aliases have been added to each container to aid in debugging and viewing logs. 

**Note: To use these aliases in the container, first run the following command: 
```source "${VOLTTRON_USER_HOME}/.bashrc"```**

All containers have the following aliases:

```shell
# vctl status
vstat

# tail the volttron logs
tlogs
``` 

Also, all containers have an environment variable, $VLOG, which is the path to each container's volttron logs. You can use $VLOG to search for certain strings in volttron.log. For example, if we want to search for "ERROR" in the 'brsw' container's volttron.log, we run the following:

```
$ cat $VLOG | grep ERROR -a
```

will search for the string "ERROR", case sensitive, in home/volttron/volttron.log

The following containers have their own specific aliases
### 'central'
```shell
# grep for building topics sent from various buildings (e.g. building1, brsw, smalloffice, largeoffice)
grep-b1
grep-brsw
grep-so
grep-lo
```

### 'building1'
```shell
# grep for campus topic sent from central forwarder
grep-cmb1
```

### 'brsw'
```shell
# grep for campus topic sent from central forwarder
grep-cmbr
```

### 'smalloffice'
```shell
# grep for campus topic sent from central forwarder
grep-cmso
```

### 'largeoffice'
```shell
# grep for campus topic sent from central forwarder
grep-cmlo
```
