#! /bin/bash

speedy=false;
if [[ $@ == -s ]]; then
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
  echo "Clear cache"
  bundle exec rake tmp:cache:clear RAILS_ENV=production
fi
# git pull --commit --no-edit
echo "Fetch origin"
git fetch origin
echo "Reset"
git reset --hard origin/master

if [[ $speedy == false ]]; then
  bundle install
  echo "Migrate"
  bundle exec rake db:migrate RAILS_ENV=production
  echo "Compile assets"
  bundle exec rake assets:precompile RAILS_ENV=production
fi

chmod u=rwx $RAILS_BASE/bin/rails
sudo service iptables start
sudo service nginx restart
