#
# startup script for AtD web service
#

#!/bin/sh

export ATD_HOME=.
export LOG_DIR=$ATD_HOME/logs

java -server -Datd.lowmem=true -Dsleep.pattern_cache_size=2048 -Dbind.interface=0.0.0.0 -Dserver.port=1049 -Xmx3840M -XX:+AggressiveHeap -XX:+UseParallelGC -Dsleep.classpath=$ATD_HOME/lib:$ATD_HOME/service/code -Dsleep.debug=24 -classpath "$ATD_HOME/lib/*" httpd.Moconti atdconfig.sl
