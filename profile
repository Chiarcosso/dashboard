# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

if [ "$PS1" ]; then
  if [ "$BASH" ] && [ "$BASH" != "/bin/sh" ]; then
    # The file bash.bashrc already sets the default PS1.
    # PS1='\h:\w\$ '
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc
    fi
  else
    if [ "`id -u`" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
  fi
fi

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

export MDC_USERNAME=chiarcosso_ws
export MDC_PASSWD=MfE3isk2Z0
export RAILS_GOOGLEMAPS_API_KEY=AIzaSyDnIaJGhem9euchdCcyxZCs4f46z22QbEE
export RAILS_MSSQL_USER=chiarcosso
export RAILS_EUROS_USER=root
export RAILS_MSSQL_PASS=chiarcosso2011!
export RAILS_EUROS_PASS=root
export RAILS_MSSQL_HOST=10.0.0.101
export RAILS_EUROS_HOST=10.0.0.101
export RAILS_MSSQL_PORT=1433
export RAILS_EUROS_PORT=3306
export RAILS_MSSQL_DB=chiarcosso
export RAILS_EUROS_DB=chiarcosso
export RAILS_WS_PATH=/mnt/wshare/DBase/Automezzi/
