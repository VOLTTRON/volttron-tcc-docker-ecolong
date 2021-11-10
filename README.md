# Prerequisites

* Docker version 20.10.5, build 55c4c88
* docker-compose version 1.28.5, build c4eb3a1f

# Notes

## Recommendations on running this Docker image on a Virtual Machine

* Memory: 16GB/16384MB
* Processor: 8 CPU's
* Storage: 40 GB

## Git Submodules
* The volttron-GS submodule is pinned to [`this commit`](https://github.com/VOLTTRON/volttron-GS/tree/803db2ba25198d33e777c3a78d4c6a0a667bc653).

## Docker
* Logs for each container are stored in `log/`; Docker will mount log/ to store all log and database files.
  This may require one to change permissions on that directory: chmod -R 777 log
* A pair of logs are created for each volttron instance. One log is dedicated to the platform configuration actions in core/setup-platform.py. That log is named <instance name>-<date>.log. It is stored in log/
  The other log captures all the log output when starting the volttron instance. That log is named <instance name>.volttron.log and is also stored in log/
* If you want to keep logs after running and then removing the docker containers, copy the "<instance name>.volttron.log" files from the log/ directory then delete the files.
  Rerunning the dockers without doing this will overwrite these log files.
* Unlike the "<instance name>.volttron.log" log files, the logs for the setup-platform.py script (i.e. "<instance name>-<date>.log") will not be overwritten when rerunning docker-compose. Instead, new logs are generated when rerunning the docker containers.
* All services defined in docker-compose.yml use the same image.

# Quickstart

1. Initialize the submodules; for details see .gitmodules

```shell
git submodule update --init --recursive
```

2. Build image without using cache and start container

```shell
docker-compose build --no-cache  --force-rm
docker-compose up
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

All containers are explicitly named in docker-compose.yml; each service defined in docker-compose.yml has a 'container_name' section. Thus, you can easily enter into a container via a human-readable container name.
For example, to enter into the Volttron central instance, use ```docker-compose exec -itu volttron central bash```.

In addition, the hostnames for the containers have also been explicitly defined in docker-compose.yml; each service has a `hostname` section. With this configuration, you know exactly which container you are in; this is helpful when opening several shells to monitor several buildings.
For example, note the shell prompt after running docker-composes exec commands below:

```shell
# shell1
$ docker-compose exec -itu volttron central bash
volttron@central:~$

# shell2
$ docker-compose exec -itu volttron building1 bash
volttron@building1:~$
```

## Aliases in the container

Aliases have been added to each container to aid in debugging and viewing logs. These aliases are defined in "$VOLTTRON_USER_HOME/.bash_aliases".

All containers have the following aliases:

```shell
# show status of all agents, i.e. 'vctl status'
vstat

# tail the volttron logs
tlogs

# tail the volttron logs and grep for 'ERROR'; this is helpful for debugging
tlogsERROR

# Search for ERROR in the logs
grep-ERROR

# restart all agents except EnergyPlus
vrestart
```

Also, all containers have an environment variable, $VLOG, which is the path to each container's volttron logs. You can use $VLOG to search for certain strings in volttron.log. For example, if we want to search for "ERROR" in the 'brsw' container's volttron.log, we run the following:

```shell
cat $VLOG | grep ERROR -a
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

# Troubleshooting

*My VC Platform agent can't connect to the Volttron Central address. I see `volttron.platform.vip.agent.subsystems.auth ERROR: Couldn't connect to https://localhost:8443 or incorrect response returned response was None` in the logs*

This most likely occurs if you are deploying this container behind a proxy. Ensure that your `~/.docker/config.json`
has no "proxies" configuration.

*My Forwarder shows a BAD status when I run `vctl status`*

Ensure that the configuration for your forwarder is using the same volttron-central-address property in volttron config, which is set in your platform_config.yml file.
