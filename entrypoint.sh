#!/bin/sh -e

# Use authbind to allow binding to port 465
exec /usr/bin/authbind --deep /srv/stunnel.sh
