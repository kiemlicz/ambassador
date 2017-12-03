FROM debian:sid
RUN apt-get update && apt-get install -y curl python-pip
COPY envoy /srv/envoy
COPY .travis/entrypoint_masterless_run.sh /opt/
COPY .travis/config/masterless.conf /etc/salt/minion.d/masterless.conf
COPY .travis/pillar /srv/pillar
RUN ln -s /srv/envoy/salt /srv/salt
RUN curl -L https://bootstrap.saltstack.com | sh
RUN ln -sf /dev/stdout /var/log/salt/minion
ARG LOG_LEVEL
ARG SALTENV
ENV LOG_LEVEL=$LOG_LEVEL
ENV SALTENV=$SALTENV

ENTRYPOINT /opt/entrypoint_masterless_run.sh $SALTENV $LOG_LEVEL
