FROM alpine:latest

# Add user and group for stunnel
RUN set -x \
       && addgroup -S stunnel \
       && adduser -S -G stunnel stunnel

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

# Copy necessary files to /srv/stunnel/
COPY *.template openssl.cnf /srv/stunnel/
COPY stunnel.sh /srv/

# Set permissions and prepare directories
RUN set -x \
       && chmod +x /srv/stunnel.sh \
       && mkdir -p /var/run/stunnel /var/log/stunnel \
       && chown -vR stunnel:stunnel /var/run/stunnel /var/log/stunnel \
       && mv -v /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.original

RUN cp -v /etc/ssl/certs/ca-certificates.crt /usr/local/share/ca-certificates/stunnel-ca.crt

# Wechsel zum nicht-root Benutzer
USER stunnel

# Set the working directory
WORKDIR /srv

# Entrypoint and command
ENTRYPOINT ["/srv/stunnel.sh"]
CMD ["stunnel"]