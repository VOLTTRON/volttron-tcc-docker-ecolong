FROM senhuang/volttron

USER root

RUN git checkout -f develop

RUN git pull

RUN rm -r /home/volttron/volttron/env


ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update && apt-get install -y build-essential python3.6-dev python3.6-venv python3-venv python3-pip openssl libssl-dev libevent-dev tzdata apt-utils

ENV TZ=US/Pacific
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

USER volttron

RUN python3 bootstrap.py --web

RUN /bin/bash -c "source env/bin/activate"

RUN pip3 install numpy jwt

ARG buildings

ARG volttron_user

USER root

RUN rm -r /home/volttron/volttron/volttron/platform/agent/base_market_agent
COPY volttron-GS/base_market_agent /home/volttron/volttron/volttron/platform/agent/base_market_agent

RUN rm /home/volttron/volttron/volttron/platform/agent/base_historian.py
COPY source/base_historian.py /home/volttron/volttron/volttron/platform/agent/base_historian.py


COPY volttron-GS/TNSAgent /home/volttron/volttron/volttron/TNS_city_Agent

COPY source/citysetup.py /home/volttron/volttron/volttron/TNS_city_Agent/setup.py

COPY volttron-GS/TNSAgent /home/volttron/volttron/volttron/TNS_campus_Agent

COPY source/campussetup.py /home/volttron/volttron/volttron/TNS_campus_Agent/setup.py

COPY volttron-GS/TNSAgent /home/volttron/volttron/volttron/TNS_building_Agent

COPY source/buildingsetup.py /home/volttron/volttron/volttron/TNS_building_Agent/setup.py



COPY volttron-GS/pnnl /home/volttron/volttron/volttron/pnnl

RUN chown volttron.volttron /home/volttron/volttron/volttron/platform/agent -R

USER volttron

RUN /bin/bash -c "source env/bin/activate"



ENV VOLTTRON_HOME=~/.volttron_${buildings}

RUN mkdir /home/volttron/.volttron_${buildings}/

COPY transactivecontrol/MarketAgents/config/${buildings}/keystore /home/volttron/.volttron_${buildings}/

COPY transactivecontrol/MarketAgents/config/${buildings}/config /home/volttron/.volttron_${buildings}/

COPY transactivecontrol/MarketAgents/config/${buildings}/auth.json /home/volttron/.volttron_${buildings}/

COPY /source/eplus /home/volttron/volttron/eplus



USER root

RUN chown volttron.volttron /home/volttron/.volttron_${buildings}/keystore

RUN chown volttron.volttron /home/volttron/.volttron_${buildings}/config

RUN chown volttron.volttron /home/volttron/.volttron_${buildings}/auth.json

RUN chown volttron.volttron /home/volttron/volttron/eplus -R

WORKDIR /home/volttron/volttron/

USER volttron