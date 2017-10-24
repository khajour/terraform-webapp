#!/usr/bin/env bash

yum update -y
yum upgrade -y
yum install -y git nginx
rm /etc/nginx/sites-enabled/default

HOST=`hostname`
git clone https://github.com/khajour/terraform-webapp.git ~/html
\cp -r ~/html/* /usr/share/nginx/html/
sed -i "s#everybody#${username} at $HOST#" /usr/share/nginx/html/index.html
#systemctl restart nginx
service nginx restart
