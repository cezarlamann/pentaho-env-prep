#!/bin/sh

### BEGIN INIT INFO
# Provides:          pentaho
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     3 4 5
# Default-Stop:      0 1 2 3 6
# Short-Description: starts Pentaho BI Server
# Description:       starts Pentaho BI Server service
### END INIT INFO

set -e

NAME="pentaho"

if [ -z "$PENTAHO_HOME" ]; then
    if [ -f /opt/pentaho/biserver-ce/start-pentaho.sh ]; then
        PENTAHO_HOME=/opt/pentaho;
        export PENTAHO_HOME=/opt/pentaho;
    else
       exit 1;
    fi
fi 

case "$1" in
  start)
        echo -n "Starting $NAME: ..."
        runuser -l  pentaho -c 'sh $PENTAHO_HOME/biserver-ce/start-pentaho.sh &'
        echo "."
        ;;

  stop)
        echo -n "Stopping $NAME ..."
        runuser -l  pentaho -c 'sh $PENTAHO_HOME/biserver-ce/stop-pentaho.sh'
        echo "Done."
        ;;

    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop}" >&2
        exit 1
        ;;  
    esac
exit
