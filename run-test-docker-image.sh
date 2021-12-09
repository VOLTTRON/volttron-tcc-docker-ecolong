#!/usr/bin/env bash

start=$(date +%s)


exit_cleanly() {
  if [ "${skip_build}" != true ]; then
    echo "Removing image: ${image_name}..."
    docker rmi --force ${image_name}
  fi
  exit
}


exit_test() {
  echo -e $1
  docker logs --tail 25 building1
  docker-compose down
  exit_cleanly
}

check_error_code() {
  local code=$1
  if [ "${code}" -ne 0 ]; then
    exit_test $2
  fi
}

# Optional parameters; defaults provided for each one
skip_build='' # skip building the image
wait=360 # 6 minutes; wait is used for sleep while the container is setting up Volttron
group='volttron' # group name of the image; will be used to name the image <group>/volttron
tag='tcc' # image tag; will be used to name the image <source image>:<tag>
while getopts 'sw:g:t:' flag; do
  case "${flag}" in
    s) skip_build=false ;;
    w) wait="$OPTARG" ;;
    g) group="$OPTARG" ;;
    t) tag="$OPTARG" ;;
    *) echo "Unexpected option ${flag}"
       exit 1 ;;
  esac
done

# Set image_name to be used in calls to docker
image_name="volttron/${group}:${tag}"
echo "Test running with following optional parameters: skip_build: ${skip_build}; wait: ${wait}; group: ${group}; tag: ${tag}"

############ Build image
if [ "${skip_build}" = true ]; then
  echo "Skipping the build"
else
  echo "Building image: ${image_name}"
  git submodule update --init --recursive
  docker rmi "${image_name}" --force
  docker build --no-cache --force-rm -t "${image_name}" .
fi

###### Test that the image was built
docker images --format "{{.Tag}}: {{.Repository}}" | grep 'develop: volttron/volttron'
check_error_code $? 'Failed to build image'

############ Setup and start container
attempts=5
echo "Will try at most ${attempts} attempts to start container..."
while [ "${attempts}" -gt 0 ]; do
  echo "Attempt number ${attempts} to start container."
  docker-compose up --detach
  echo "Configuring and starting Volttron platform; this will take approximately several minutes........"
  sleep ${wait}
  docker ps --filter "name=building1" --filter "status=running" | grep 'building1'
  tmp_code=$?
  if [ "${tmp_code}" -eq 1 ]; then
    echo "Container failed to start."
    docker logs --tail 20 building1
    docker-compose down
    ((attempts=attempts-1))
  else
    # Container was successfully created
    break
  fi
done

############ Shutdown container/cleanup
exit_cleanly
