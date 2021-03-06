# VERSION 1.9.0-2
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.6-slim
MAINTAINER Puckel_

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ENV AIRFLOW_GPL_UNIDECODE=yes
ARG AIRFLOW_VERSION=1.10.0
ENV AIRFLOW_HOME /usr/local/airflow

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN buildDeps=' \
        libkrb5-dev \
        libsasl2-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
    ' \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        $buildDeps \
        python3-dev \
        libffi-dev \
        python3-pip \
        python3-requests \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        git \
        libssl-dev \
        libxml2-dev \
        libpq-dev \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install --no-cache-dir -U pip setuptools wheel \
    && pip install --no-cache-dir Cython \
    && pip install --no-cache-dir pytz \
    && pip install --no-cache-dir pyOpenSSL \
    && pip install --no-cache-dir ndg-httpsclient \
    && pip install --no-cache-dir pyasn1 \
    && pip install --no-cache-dir apache-airflow[crypto,celery,postgres,hive,jdbc]==$AIRFLOW_VERSION \
    && pip install --no-cache-dir celery[redis]==4.1.1 \
    && apt-get purge --auto-remove -y $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

# Install additional packages
RUN pip install 'git+https://github.com/kuberlab/python-mlboardclient'

COPY script/entrypoint.sh ${AIRFLOW_HOME}/entrypoint.sh

RUN mkdir -p ${AIRFLOW_HOME}/confgen
RUN chmod +x ${AIRFLOW_HOME}/entrypoint.sh
RUN chown -R airflow: ${AIRFLOW_HOME} \
    && chown -R airflow: ${AIRFLOW_HOME}/confgen \
    && chmod +x ${AIRFLOW_HOME}/entrypoint.sh

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["./entrypoint.sh"]
VOLUME [ "/usr/local/airflow/confgen","/usr/local/airflow/dags"]
