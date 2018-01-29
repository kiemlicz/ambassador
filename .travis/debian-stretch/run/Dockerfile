FROM debian:stretch

ARG FQDN

COPY .travis/config/ssl/*.key /etc/ssl/private/
COPY .travis/config/ssl/*.cert /etc/ssl/certs/
COPY .travis/config/ssl/crl.pem /etc/ssl/
COPY .travis/config/foreman.yaml /etc/salt/
COPY .travis/config/proxydhcp.conf /etc/dnsmasq.d/
COPY .travis/config/salt.yml /etc/foreman-proxy/settings.d/
COPY config/file_ext_authorize.service /etc/systemd/system/
COPY .travis/config/file_ext_authorize.conf /opt/file_ext_authorize/
COPY extensions/file_ext_authorize/* /opt/file_ext_authorize/
COPY run.sh /opt/

RUN apt-get clean && apt-get update && apt-get install -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV CID=$FQDN
ENV CIP="192.168.1.7"
ENV CRL="/etc/ssl/crl.pem"
ENV CA="/etc/ssl/certs/ca.cert"
ENV CERT="/etc/ssl/certs/server.cert"
ENV PROXY_CERT="/etc/ssl/certs/server.cert"
ENV KEY="/etc/ssl/private/server.key"
ENV PROXY_KEY="/etc/ssl/private/server.key"
ENV CERT_BASEDIR="/etc/ssl/"
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#fixme - debug permission issue during installation
#RUN chmod 644 /etc/ssl/private/server.key && chown root.foreman /etc/ssl/private/server.key

ENTRYPOINT ["/opt/run.sh"]
