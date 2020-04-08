IMG_NAME=${building}

COMMAND_RUN=docker run \
	  --name ${IMG_NAME} \
	  --detach=false \
	  --network host \
	  -e DISPLAY=${DISPLAY} \
	  -v /tmp/.X11-unix:/tmp/.X11-unix \
	  --rm \
	  -v `pwd`/transactivecontrol/MarketAgents:/home/volttron/volttron/config \
	  -v `pwd`/upgrade-scripts:/home/volttron/volttron/upgrade-scripts \
	  -v `pwd`/volttron-GS:/home/volttron/volttron/transactivecontrol \
	  -v `pwd`/source/bcvtb:/home/volttron/volttron/bcvtb \
	  -i \
          -t \
	  ${IMG_NAME} /bin/bash -c

build:
	docker build --build-arg buildings=${IMG_NAME} --network host --no-cache --rm -t ${IMG_NAME} .
 
remove-image:
	docker rmi ${IMG_NAME}

run:
	$(COMMAND_RUN) \
            " bash"

run_b1:
	$(COMMAND_RUN) \
            "bash upgrade-scripts/upgrade-b1-tns && bash"
