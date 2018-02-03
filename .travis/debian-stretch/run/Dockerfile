FROM debian:stretch

ARG FQDN

COPY .travis/config/ssl/*.key /etc/foreman/ssl/private/
COPY .travis/config/ssl/*.cert /etc/foreman/ssl/certs/
COPY .travis/config/ssl/crl.pem /etc/foreman/ssl/
COPY .travis/config/foreman.yaml /etc/salt/
COPY .travis/config/30-saltfs.conf /var/tmp/
COPY .travis/config/proxydhcp.conf /etc/dnsmasq.d/
COPY .travis/config/salt.yml /etc/foreman-proxy/settings.d/
COPY config/file_ext_authorize.service /etc/systemd/system/
COPY .travis/config/file_ext_authorize.conf /opt/file_ext_authorize/
COPY extensions/file_ext_authorize/* /opt/file_ext_authorize/
COPY run.sh /opt/

RUN apt-get clean && apt-get update && apt-get install -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV CID=$FQDN
# fixed, fake IP
ENV CIP="192.168.1.7"
ENV CRL="/etc/foreman/ssl/crl.pem"
ENV CA="/etc/foreman/ssl/certs/ca.cert"
ENV CERT="/etc/foreman/ssl/certs/server.cert"
ENV PROXY_CERT="/etc/foreman/ssl/certs/server.cert"
ENV KEY="/etc/foreman/ssl/private/server.key"
ENV PROXY_KEY="/etc/foreman/ssl/private/server.key"
ENV CERT_BASEDIR="/etc/foreman/ssl/"
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


ENTRYPOINT ["/opt/run.sh"]
