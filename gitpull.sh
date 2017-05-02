#! /bin/bash
slow = true
if [ $1 == '-s']; then
    slow = false
fi
sudo service iptables stop
sudo service nginx stop
if [ $slow == true ]; then
  bundle exec rake tmp:cache:clear RAILS_ENV=production
fi
git pull
if [ $slow == true ]; then
  bundle exec rake db:migrate RAILS_ENV=production
  bundle exec rake assets:precompile RAILS_ENV=production
  bundle install
fi
sudo service iptables start
sudo service nginx start
