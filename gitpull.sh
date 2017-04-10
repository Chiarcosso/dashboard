#! /bin/bash

sudo service iptables stop
sudo service nginx stop
bundle exec rake tmp:cache:clear RAILS_ENV=production
sudo git pull
sudo service iptables start
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rvmsudo rake assets:precompile RAILS_ENV=production
sudo service nginx start
