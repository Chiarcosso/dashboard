#! /bin/bash
let $speedy = false;
if [ -o '-s']
  then
    let $speedy = true;
fi
sudo service iptables stop
sudo service nginx stop
if [[ $speedy == false ]]; then
  bundle exec rake tmp:cache:clear RAILS_ENV=production
fi
git pull
if [[ $speedy == false ]]; then
  bundle exec rake db:migrate RAILS_ENV=production
  bundle exec rake assets:precompile RAILS_ENV=production
  bundle install
fi
sudo service iptables start
sudo service nginx start
