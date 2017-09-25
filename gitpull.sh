#! /bin/bash

speedy=false;
if [ $1='-s' ]
  then
    speedy=true;
fi

sudo service iptables stop
#sudo service nginx stop

# FN="log/production-$(date +%Y%m%d-%H%M%S).log"
# sudo mv ./log/production.log $FN
# touch ./log/production.log
# sudo chown dashboard:nginx log/production.log
# sudo chmod 664 log/production.log

if [[ $speedy == false ]]; then
  bundle exec rake tmp:cache:clear RAILS_ENV=production
fi
git pull --commit --no-edit

if [[ $speedy == false ]]; then
  bundle install
  bundle exec rake db:migrate RAILS_ENV=production
  bundle exec rake assets:precompile RAILS_ENV=production
fi

sudo service iptables start
sudo service nginx restart
