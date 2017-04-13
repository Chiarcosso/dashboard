#! /bin/bash

sudo service iptables stop
sudo service nginx stop
rvmsudo bundle exec rake tmp:cache:clear RAILS_ENV=production
sudo git pull
bundle exec rake db:migrate RAILS_ENV=production
rvmsudo bundle exec rake assets:precompile RAILS_ENV=production
sudo service iptables start
sudo service nginx start
