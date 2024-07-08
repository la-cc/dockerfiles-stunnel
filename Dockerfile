FROM debian:latest

# Create the group and user "stunnel"
RUN set -x \
       && groupadd -r stunnel \
       && useradd -r -g stunnel stunnel

# Install necessary packages as root
RUN apt-get update && apt-get install -y \
       ca-certificates \
       gettext-base \
       openssl \
       stunnel4 \
       authbind \
       && rm -rf /var/lib/apt/lists/*

# Copy configuration files and scripts
COPY stunnel.conf.template /srv/stunnel/stunnel.conf.template
COPY openssl.cnf /srv/stunnel/openssl.cnf
COPY stunnel.sh /srv/stunnel.sh

# Set up directories and permissions
RUN set -x \
       && chmod +x /srv/stunnel.sh \
       && mkdir -p /var/run/stunnel /var/log/stunnel \
       && chown -R stunnel:stunnel /var/run/stunnel /var/log/stunnel

# Ensure the stunnel configuration directory exists and create an initial config file if needed
RUN mkdir -p /etc/stunnel \
       && echo "pid = /var/run/stunnel.pid" > /etc/stunnel/stunnel.conf \
       && mv -v /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.original

# Create certificates and CA files as root
RUN cp -v /etc/ssl/certs/ca-certificates.crt /usr/local/share/ca-certificates/stunnel-ca.crt

# Pre-create the stunnel.conf file and set permissions
RUN touch /etc/stunnel/stunnel.conf \
       && chown stunnel:stunnel /etc/stunnel/stunnel.conf

# Configure authbind for stunnel user
RUN mkdir -p /etc/authbind/byport \
       && touch /etc/authbind/byport/465 \
       && chown stunnel /etc/authbind/byport/465 \
       && chmod 500 /etc/authbind/byport/465

# Switch to non-root user
USER stunnel

# Set working directory
WORKDIR /srv

# Define entrypoint and CMD
ENTRYPOINT ["/usr/bin/authbind", "/srv/stunnel.sh"]
CMD ["stunnel"]
