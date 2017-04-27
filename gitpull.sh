#! /bin/bash

sudo service iptables stop
sudo service nginx stop
bundle exec rake tmp:cache:clear RAILS_ENV=production
git pull
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake assets:precompile RAILS_ENV=production
bundle install
sudo service iptables start
sudo service nginx start
