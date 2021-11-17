#!/bin/bash

if [ -z $1 ]
then
  echo "You need to pass a step number"
  exit 1;
fi

if [ $1 != 8 ]
then
  sudo cp -R step_$1/conf.d /etc/nginx
fi

if [ $1 = 6 ]
then
  sudo cp -R step_6/api_secret.jwk /etc/nginx/api_secret.jwk
fi
if [ $1 = 7 ]
then
  sudo cp -R step_7/nginx.conf /etc/nginx/nginx.conf
fi
if [ $1 = 8 ]
then
  sudo cp -R step_8/nginx.conf /etc/nginx/nginx.conf
  sudo cp -R step_8/nginx_api_security_policy.json /etc/nginx/nginx_api_security_policy.yml
  sudo cp -R step_8/ergast_f1_oas.yml /etc/nginx/ergast_f1_oas.yml
fi

sudo nginx -s reload
if [ $? = 0 ]
then
  echo "NGINX successfully reloaded"
fi

