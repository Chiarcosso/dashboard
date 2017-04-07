#! /bin/bash

sudo service iptables stop
git pull
sudo service iptables start
RAILS_ENV=production bundle exec rake tmp:cache:clear
RAILS_ENV=production bundle exec rake db:migrate
bundle exec rvmsudo rake assets:precompile RAILS_ENV=production
sudo service nginx restart
