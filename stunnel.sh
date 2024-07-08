#!/bin/sh -e

export STUNNEL_CONF="/etc/stunnel/stunnel.conf"
export STUNNEL_DEBUG="${STUNNEL_DEBUG:-7}"
export STUNNEL_UID="${STUNNEL_UID:-stunnel}"
export STUNNEL_GID="${STUNNEL_GID:-stunnel}"
export STUNNEL_CLIENT="${STUNNEL_CLIENT:-no}"
export STUNNEL_VERIFY="${STUNNEL_VERIFY:-0}"
#export STUNNEL_SNI="${STUNNEL_SNI:-}"
export STUNNEL_CAFILE="${STUNNEL_CAFILE:-/etc/ssl/certs/ca-certificates.crt}"
export STUNNEL_VERIFY_CHAIN="${STUNNEL_VERIFY_CHAIN:-no}"
export STUNNEL_KEY="${STUNNEL_KEY:-/etc/stunnel/stunnel.key}"
export STUNNEL_CRT="${STUNNEL_CRT:-/etc/stunnel/stunnel.pem}"
export STUNNEL_DELAY="${STUNNEL_DELAY:-no}"
export STUNNEL_PROTOCOL_CONFIG_LINE=${STUNNEL_PROTOCOL:+protocol = ${STUNNEL_PROTOCOL}}

# Check if required environment variables are set
if [ -z "${STUNNEL_SERVICE}" ] || [ -z "${STUNNEL_ACCEPT}" ] || [ -z "${STUNNEL_CONNECT}" ]; then
    echo >&2 "one or more STUNNEL_SERVICE* values missing: "
    echo >&2 "  STUNNEL_SERVICE=${STUNNEL_SERVICE}"
    echo >&2 "  STUNNEL_ACCEPT=${STUNNEL_ACCEPT}"
    echo >&2 "  STUNNEL_CONNECT=${STUNNEL_CONNECT}"
    exit 1
fi

# Generate SSL key and certificate if they do not exist
if [ ! -f "${STUNNEL_KEY}" ]; then
    if [ -f "${STUNNEL_CRT}" ]; then
        echo >&2 "crt (${STUNNEL_CRT}) missing key (${STUNNEL_KEY})"
        exit 1
    fi

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "${STUNNEL_KEY}" -out "${STUNNEL_CRT}" \
        -config /srv/stunnel/openssl.cnf
fi

# Create the stunnel configuration file if it does not exist
if [ ! -s "${STUNNEL_CONF}" ]; then
    cat /srv/stunnel/stunnel.conf.template | envsubst | awk '{$1=$1};1' >"${STUNNEL_CONF}"
fi

# Run stunnel in the background
stunnel &

# Use socat to forward traffic from high port to low port
exec socat TCP4-LISTEN:465,fork TCP4:127.0.0.1:4465
