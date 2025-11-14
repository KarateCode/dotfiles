#!/bin/bash

echo 'Fixing nginx so that awt.loc can run again...'
cd /var/log
sudo mkdir nginx
cd nginx
sudo touch access.log
sudo touch error.log
chmod 0644 access.log
chmod 0644 error.log
sudo nginx

# tweaks to conf can be made at /usr/local/etc/nginx/nginx.conf
# to stop nginx:
# sudo nginx -s stop
# to start nginx:
# sudo nginx

echo 'Finished!  This should provide proof:'
ps -ef | grep nginx⏎
