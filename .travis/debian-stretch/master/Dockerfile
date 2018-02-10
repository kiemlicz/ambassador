FROM debian:stretch

ARG saltenv
ARG log_level
# "" == latest
ARG salt_ver=""

COPY envoy /srv/envoy
COPY .travis/entrypoint_master_run.sh /opt/
COPY .travis/scan_events.py /opt/
COPY .travis/config/master.conf /etc/salt/master.d/master.conf
COPY .travis/config/reactor_master.conf /etc/salt/master.d/reactor.conf
COPY .travis/config/supervisord_master.conf /etc/supervisor/conf.d/supervisord.conf
COPY .travis/pillar /srv/pillar
COPY .travis/salt/dev/top.sls /srv/envoy/salt/dev/

RUN apt-get update && \
    apt-get install -y curl supervisor procps && \
    ln -s /srv/envoy/salt /srv/salt && \
    ln -s /srv/envoy/extensions /srv/salt_ext && \
    ln -s /srv/envoy/reactor /srv/reactor

COPY .travis/reactor /srv/reactor

EXPOSE 4505:4505 4506:4506

ENV LOG_LEVEL=$log_level
ENV SALTENV=$saltenv
ENTRYPOINT [ "/opt/entrypoint_master_run.sh" ]
CMD [ "$salt_ver" ]
