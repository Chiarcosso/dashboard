#! /bin/bash

source /etc/profile

#temporary disable firewall
service iptables stop

#mount shared folder
mount.cifs $RAILS_CAME_HOST $RAILS_CAME_LOCAL -o user=$RAILS_CAME_USER,pass=$RAILS_CAME_PASS,ro,sec=ntlm,iocharset=utf8,uid=dashboard

#if succedes call the read_timestamps method
if [ $? -eq 0 ]
then
  #copy contents to local path
  cp $RAILS_CAME_PATH/* $RAILS_CAME_LOCAL_PATH/

  #unmount the folder
  umount $RAILS_CAME_LOCAL

  cd $RAILS_BASE
  #give execute rights to bundle
  chmod u+x bin/bundle

  #execute reading
  su -lc "cd $RAILS_BASE && bin/bundle exec bin/rails runner -e production 'PresenceController::read_timestamps'" dashboard

  #revoke rights
  chmod u-x bin/bundle
fi

#reenable firewall
service iptables start
