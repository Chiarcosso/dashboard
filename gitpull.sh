#! /bin/bash

sudo service iptables stop
git pull
sudo service iptables start
RAILS_ENV=production bundle-exec rake db:migrate
sudo service nginx restart
