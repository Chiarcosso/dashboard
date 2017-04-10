#! /bin/bash

sudo service iptables stop
sudo service nginx stop
RAILS_ENV=production bundle exec rake tmp:cache:clear
sudo git pull
sudo service iptables start
RAILS_ENV=production bundle exec rake db:migrate
bundle exec rvmsudo rake assets:precompile RAILS_ENV=production
sudo service nginx start
