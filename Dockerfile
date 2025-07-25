FROM public.ecr.aws/lambda/python:3.13 AS base

RUN dnf -y update \
 && dnf -y install \
  python3-pip clamav \
  clamav-lib \
  clamav-scanner-systemd \
  clamav-update \
 && dnf clean all \
 && echo "DatabaseMirror database.clamav.net" > /etc/freshclam.conf \
 && echo "CompressLocalDatabase yes" >> /etc/freshclam.conf \
 && chmod a+r /etc/freshclam.conf

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt \
 && rm -rf /root/.cache/pip

COPY *.py .

FROM base AS tests

RUN [[ $(python --version) == "Python 3.12."* ]]

COPY . .

RUN pip install -r requirements-dev.txt \
 && rm -rf /root/.cache/pip
RUN nosetests
RUN flake8

FROM base AS lambda

CMD [ "update.lambda_handler" ]

