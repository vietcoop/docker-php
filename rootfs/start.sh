#!/bin/bash

# Trigger called to secretsmanager. Allow to run its in local
# if [ ! -z "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ] && [ ! -z "$AWS_SECRET_NAME" ]; then
#   eval `secretsmanager $AWS_SECRET_NAME`
# fi

# Set custom webroot
if [ ! -z "$WEBROOT" ]; then
  webroot=$WEBROOT
  sed -i "s#root /app/public;#root ${webroot};#g" /etc/nginx/sites-available/default.conf
else
  webroot=/app/public
fi

if [ ! -z "$DD_SERVICE_NAME" ]; then
  service=$DD_SERVICE_NAME
elif [ ! -z "$SERVICE_80_NAME" ]; then
  service=$SERVICE_80_NAME
elif [ ! -z "$SERVICE_NAME" ]; then
  service=$SERVICE_NAME
else
  service="nginx"
fi

if [ ! -z "$DATADOG_ENV" ]; then
  service_env=$DATADOG_ENV
elif [ ! -z "$SERVICE_TAGS" ]; then
  service_env=$SERVICE_TAGS
elif [ ! -z "$SERVICE_ENV" ]; then
  service_env=$SERVICE_ENV
else
  service_env="dev"
fi

if [ -z "$DD_SERVICE_NAME" ]; then
  DD_SERVICE_NAME=$service
fi

if [ -z "$DD_TRACE_GLOBAL_TAGS"]; then
  DD_TRACE_GLOBAL_TAGS="env:$service_env"
fi

if [ -f "/etc/datadog-config.json" ]; then
  sed -i "s#SERVICE_NAME#$service#g" /etc/datadog-config.json
  sed -i "s#SERVICE_ENV#$service_env#g" /etc/datadog-config.json
fi

sed -i "s#SERVICE_NAME#$service#g" /etc/nginx/sites-available/default.conf
sed -i "s#SERVICE_ENV#$service_env#g" /etc/nginx/sites-available/default.conf

# Check and disable opentracing if we don't have DD_AGENT_HOST
if [ ! -z "$DD_AGENT_HOST" ]; then
  sed -i "s#DD_AGENT_HOST#$DD_AGENT_HOST#g" /etc/datadog-config.json
else
  sed -i "s#load_module modules/ngx_http_opentracing_module.so#\#load_module#g" /etc/nginx/nginx.conf
  sed -i "s#opentracing#\#opentracing#g" /etc/nginx/nginx.conf
  sed -i "s#opentracing#\#opentracing#g" /etc/nginx/sites-available/default.conf
  # Disabled for local
  DD_TRACE_ENABLED=false
fi

# Set custom location root
if [ ! -z "$LOCATIONROOT" ]; then
  location=$LOCATIONROOT
  sed -i "s#location / {#location ${location} {#g" /etc/nginx/sites-available/default.conf
  sed -i "s#/index.php#${location}/index.php#g" /etc/nginx/sites-available/default.conf
fi

# Always chown webroot for better mounting
chown -Rf www-data.www-data $webroot

# Convert env
vars=`set | grep _DOCKER_`

for var in $vars
do
    key=$(echo "$var" | sed -E 's/_DOCKER_([^=]+).+/\1/g')
    var=$(echo "$var" | sed -E 's/_DOCKER_([^=]+).+/_DOCKER_\1/g')
    eval val=\$$var
    if [ "$val" ]; then
      export ${key}=${val}
    fi
    unset $var
done

# Allow run custom script
if [ ! -z "$SCRIPT" ] && [ -f "$SCRIPT" ]; then
  chmod a+x $SCRIPT
  . $SCRIPT
fi

if [ -f /app/resources/docker/hook-start ]; then
    source /app/resources/docker/hook-start
fi

php-fpm

nginx -g "daemon off;"
