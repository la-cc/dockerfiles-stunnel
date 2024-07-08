FROM alpine:latest

# Create the group and user "stunnel"
RUN set -x \
       && addgroup -S stunnel \
       && adduser -S -G stunnel stunnel

# Install necessary packages as root
RUN apk add --update --no-cache \
       ca-certificates \
       libintl \
       openssl \
       stunnel \
       && grep main /etc/apk/repositories > /etc/apk/main.repo \
       && apk add --update --no-cache --repositories-file=/etc/apk/main.repo \
       gettext \
       && cp -v /usr/bin/envsubst /usr/local/bin/ \
       && apk del --purge \
       gettext \
       && apk --no-network info openssl \
       && apk --no-network info stunnel

# Copy configuration files and scripts
COPY *.template openssl.cnf /srv/stunnel/
COPY stunnel.sh /srv/

# Set up directories and permissions
RUN set -x \
       && chmod +x /srv/stunnel.sh \
       && mkdir -p /var/run/stunnel /var/log/stunnel \
       && chown -vR stunnel:stunnel /var/run/stunnel /var/log/stunnel \
       && mv -v /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.original

# Create certificates and CA files as root
RUN cp -v /etc/ssl/certs/ca-certificates.crt /usr/local/share/ca-certificates/stunnel-ca.crt

# Pre-create the stunnel.conf file and set permissions
RUN touch /etc/stunnel/stunnel.conf \
       && chown stunnel:stunnel /etc/stunnel/stunnel.conf

# Switch to non-root user
USER stunnel

# Set working directory
WORKDIR /srv

# Define entrypoint and CMD
ENTRYPOINT ["/srv/stunnel.sh"]
CMD ["stunnel"]
