ARG image_user=amd64
ARG image_repo=ubuntu
ARG image_tag=focal

FROM ${image_user}/${image_repo}:${image_tag} as volttron_base

SHELL [ "bash", "-c" ]

ENV OS_TYPE=${image_user}
ENV DIST=${image_repo}
ENV VOLTTRON_GIT_BRANCH=rabbitmq-volttron
ENV VOLTTRON_USER_HOME=/home/volttron
ENV VOLTTRON_HOME=${VOLTTRON_USER_HOME}/.volttron
ENV CODE_ROOT=/code
ENV VOLTTRON_ROOT=${CODE_ROOT}/volttron
ENV VOLTTRON_USER=volttron
ENV USER_PIP_BIN=${VOLTTRON_USER_HOME}/.local/bin
ENV RMQ_ROOT=${VOLTTRON_USER_HOME}/rabbitmq_server
ENV RMQ_HOME=${RMQ_ROOT}/rabbitmq_server-3.7.7
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=America/Los_Angeles

USER root

# ubuntu bioinic image does not come with /etc/timezone or /etc/localtime, resulting in UTC warnings on every vctl command
# need to manually add tzdata and configure timezone here
RUN echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y tzdata
RUN rm /etc/localtime
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
RUN dpkg-reconfigure -f noninteractive tzdata

RUN set -eux; apt-get update --fix-missing; apt-get install -y --no-install-recommends \
    procps \
    gosu \
    vim \
    tree \
    build-essential \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    openssl \
    libssl-dev \
    libevent-dev \
    git \
    gnupg \
    dirmngr \
    apt-transport-https \
    wget \
    curl \
    ca-certificates \
    libffi-dev \
    locales \
    default-jdk \
    iputils-ping

# Download and install energyplus 8.5.0
# DO NOT update to latest version; IDF files for energyplus are not backward compatible
RUN wget https://github.com/NREL/EnergyPlus/releases/download/v8.5.0/EnergyPlus-8.5.0-c87e61b44b-Linux-x86_64.sh
# This command will automate the interactive installation script by automatically answering the three questions being presented:
# The printf command mimics the manual action of entering "yes" followed by two "enter" commands to accept the default configuration
RUN printf 'y\n\n\n\n\n' | bash EnergyPlus-8.5.0-c87e61b44b-Linux-x86_64.sh

RUN locale-gen en_US.UTF-8

RUN id -u $VOLTTRON_USER &>/dev/null || adduser --disabled-password --gecos "" $VOLTTRON_USER

RUN mkdir -p /code && chown $VOLTTRON_USER.$VOLTTRON_USER /code \
  && echo "export PATH=/home/volttron/.local/bin:$PATH" > /home/volttron/.bashrc

############################################
# ENDING volttron_base image
############################################

FROM volttron_base AS volttron_core

RUN ln -s /usr/bin/pip3 /usr/bin/pip

USER $VOLTTRON_USER
COPY --chown=volttron:volttron volttron /code/volttron
WORKDIR /code/volttron
RUN pip3 install -e . --user
RUN echo "package installed at `date`"

USER root
RUN mkdir /startup $VOLTTRON_HOME && \
    chown $VOLTTRON_USER.$VOLTTRON_USER $VOLTTRON_HOME
COPY ./core/entrypoint.sh /startup/entrypoint.sh
COPY ./core/bootstart.sh /startup/bootstart.sh
COPY ./core/setup-platform.py /startup/setup-platform.py
COPY ./core/slogger.py /startup/slogger.py
RUN chmod +x /startup/*

############################################
# ENDING volttron_core image
############################################
FROM volttron_core AS volttron_tcc
ARG BUILDINGS

USER $VOLTTRON_USER
# TODO: try to install web dependencies here instead of in core/setup-platform.py
#WORKDIR /code/volttron
#RUN pip3 install <the web dependencies in requirements.py>
RUN pip3 install pandas sympy transitions scipy patsy decorators
RUN echo "alias vstat='vctl status'" >> "$VOLTTRON_USER_HOME/.bash_aliases"
RUN echo "source ~/.bash_aliases" >> "$VOLTTRON_USER_HOME/.bashrc"

COPY --chown=volttron:volttron volttron-GS/pnnl /code/volttron/volttron/pnnl
COPY --chown=volttron:volttron volttron-GS/eplus /code/volttron/volttron/pnnl
COPY --chown=volttron:volttron source/eplus /code/volttron/volttron/eplus

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


