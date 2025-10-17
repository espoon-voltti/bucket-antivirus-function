FROM public.ecr.aws/lambda/python:3.13 AS base

RUN dnf -y update \
 && dnf -y install python3-pip \
 && dnf clean all

ARG CLAMAV_SHA256="d457b7a40f8bd3a6a427df73bfcaa90509eca6cde4ee9aa70db15a56a3e7cb00"
ARG CLAMAV_VERSION="1.5.1"

RUN curl -sSfL "https://www.clamav.net/downloads/production/clamav-${CLAMAV_VERSION}.linux.x86_64.rpm"  -o /tmp/clamav-1.5.1.linux.x86_64.rpm \
 && echo "${CLAMAV_SHA256}  /tmp/clamav-${CLAMAV_VERSION}.linux.x86_64.rpm" | sha256sum -c - \
 && rpm -i /tmp/clamav-1.5.1.linux.x86_64.rpm \
 && echo "DatabaseMirror database.clamav.net" > /etc/freshclam.conf \
 && echo "CompressLocalDatabase yes" >> /etc/freshclam.conf \
 && chmod a+r /etc/freshclam.conf

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt \
 && rm -rf /root/.cache/pip

COPY *.py .

FROM base AS tests

RUN [[ $(python --version) == "Python 3.13."* ]]

COPY . .

RUN pip install -r requirements-dev.txt \
 && rm -rf /root/.cache/pip
RUN nosetests
RUN flake8

FROM base AS lambda

CMD [ "update.lambda_handler" ]

