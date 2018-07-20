#! /bin/bash

source /etc/profile

#temporary disable firewall
service iptables stop

#mount shared folder
mount.cifs $RAILS_CAME_HOST $RAILS_CAME_LOCAL -o user=$RAILS_CAME_USER,pass=$RAILS_CAME_PASS,ro,sec=ntlm,iocharset=utf8,uid=dashboard

#if succedes call the read_timestamps method
if [ $? -eq 0 ]
then
  cd $RAILS_BASE
  chmod u+x bin/bundle
  su -lc "cd $RAILS_BASE && bin/bundle exec bin/rails runner -e production 'PresenceController::read_timestamps'" dashboard
  chmod u-x bin/bundle
fi

#unmount the folder
umount $RAILS_CAME_LOCAL

#reenable firewall
service iptables start
