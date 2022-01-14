FROM eclipsevolttron/volttron:v3.1 as volttron_base

# overwrite the base image's bootstart with our custom bootstart
COPY ./core/bootstart.sh /startup/bootstart.sh
RUN chmod +x /startup/*

# Must ensure pip is upgraded or else scipy will not be installed
RUN pip install --upgrade pip

RUN set -eux && apt-get update --fix-missing  && apt-get install -y --no-install-recommends locales \
    default-jdk \
    iputils-ping

# Download and install energyplus 8.5.0
# DO NOT update to latest version; IDF files for energyplus are not backward compatible
RUN wget https://github.com/NREL/EnergyPlus/releases/download/v8.5.0/EnergyPlus-8.5.0-c87e61b44b-Linux-x86_64.sh

# This command will automate the interactive installation script by automatically answering the three questions being presented:
# The printf command mimics the manual action of entering "yes" followed by two "enter" commands to accept the default configuration
RUN printf 'y\n\n\n\n\n' | bash EnergyPlus-8.5.0-c87e61b44b-Linux-x86_64.sh

ARG BUILDINGS
USER $VOLTTRON_USER

RUN pip install pandas sympy transitions scipy patsy decorators
RUN echo "alias vstat='vctl status'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
RUN echo "source ~/.bash_aliases" >> "$VOLTTRON_USER_HOME/.bashrc"

COPY --chown=volttron:volttron volttron-GS/pnnl /code/volttron/volttron/pnnl
COPY --chown=volttron:volttron volttron-GS/eplus /code/volttron/volttron/pnnl

COPY --chown=volttron:volttron volttron-GS/MarketAgents /code/volttron/volttron/MarketAgents
COPY --chown=volttron:volttron volttron-GS/MixMarketServiceAgent /code/volttron/volttron/MixMarketServiceAgent
COPY --chown=volttron:volttron volttron-GS/base_market_agent /code/volttron/volttron/platform/agent/base_market_agent

COPY --chown=volttron:volttron volttron-GS/TNSAgent /code/volttron/volttron/TNS_city_Agent
COPY --chown=volttron:volttron source/citysetup.py /code/volttron/volttron/TNS_city_Agent/setup.py

COPY --chown=volttron:volttron volttron-GS/TNSAgent /code/volttron/volttron/TNS_campus_Agent
COPY --chown=volttron:volttron source/campussetup.py /code/volttron/volttron/TNS_campus_Agent/setup.py

COPY --chown=volttron:volttron volttron-GS/TNSAgent /code/volttron/volttron/TNS_building_Agent
COPY --chown=volttron:volttron source/buildingsetup.py /code/volttron/volttron/TNS_building_Agent/setup.py


########################################
# The following lines should be run from any Dockerfile-old that
# is inheriting from this one as this will make the volttron
# run in the proper location.
#
# The user must be root at this point to allow gosu to work
########################################
USER root
WORKDIR ${VOLTTRON_USER_HOME}
ENTRYPOINT ["/startup/entrypoint.sh"]
CMD ["/startup/bootstart.sh"]
