FROM ubuntu:trusty

MAINTAINER Michael Smith <Michael.smith.erdc@gmail.com>

RUN apt-get update && apt-get install -y \
    git libxml2-dev python2.7 build-essential make gcc python2.7-dev locales python-pip python-docutils libaio1 \
    unzip  curl python-virtualenv  libffi6 openssl python2.7-numpy libxslt-dev lib32z1-dev libbz2-dev libexpat1-dev \
    libgeos-dev libgif-dev libjpeg62-turbo-dev libncurses5-dev libc6-dev libgdal1h python-gdal vim

RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LC_ALL C.UTF-8

ARG UID
ARG GID

RUN addgroup --gid $GID gridgrp
RUN adduser  --disabled-login gridusr --gecos "" --uid $UID --gid $GID

COPY instantclient_12_1 /opt/instantclient/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/instantclient/

ENV ORACLE_HOME /opt/instantclient
RUN export ORACLE_HOME=/opt/instantclient

RUN curl -L https://raw.githubusercontent.com/dockito/vault/master/ONVAULT > /usr/local/bin/ONVAULT && \
    chmod +x /usr/local/bin/ONVAULT

RUN apt-get remove -y python-pip && curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py
RUN pip install wheel
ENV VAULT_URI="172.17.0.1:14242"
USER gridusr

RUN cd /home/gridusr/ \
  && ONVAULT git clone git@github.com:CRREL/GRiD.git \
  && cd GRiD \
  && virtualenv -p /usr/bin/python virtualenv/production \
  && . virtualenv/production/bin/activate \
  && ONVAULT git submodule update --init --recursive \
  && pip install pip --upgrade \
  && pip install wheel --upgrade \
  && pip install docutils \
  && pip install Django==1.8.4 \
  && pip install -r requirements/base.txt \
  && ONVAULT scp gridusr@172.31.11.0:/home/gridusr/GRiD/settings_local.py . \
  && sed -i '/^GDAL_LIBRARY/d' settings_local.py

ENV PYTHONPATH=$PYTHONPATH:/usr/lib/python2.7/dist-packages

CMD ["cd /home/gridusr/GRiD; source virtualenv/production/bin/activate; fab serve"]

EXPOSE 8000