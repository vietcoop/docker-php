#!/bin/bash

# Always chown webroot for better mounting
chown -Rf www-data.www-data /app/public

if [ -f /app/resources/docker/hook-start ]; then
    source /app/resources/docker/hook-start
fi

/usr/bin/supervisord -n -c /etc/supervisord.conf
