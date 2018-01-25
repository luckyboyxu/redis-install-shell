start () {
        if [ -f $PIDFILE ]
        then
                echo "$PIDFILE exists, process is already running or crashed"
        else
                echo "Starting Redis server($role)..."
                $EXEC $CONF
        fi
}

stop () {
        if [ ! -f $PIDFILE ]
        then
                echo "$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "Stopping ..."
                $CLIEXEC -p $REDISPORT shutdown
                while [ -x /proc/${PID} ]
                do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                    $CLIEXEC -p $REDISPORT shutdown
                done
                echo "Redis stopped"
        fi
}

restart () {
    stop
    start
}

case "$1" in
    start)
        stop
        role="master"
        sed -i '/^slaveof/d' $CONF
        sed -i '/^save /d' $CONF
        start
        ;;
    stop)
        stop
        role="slave"
        sed -i '/^slaveof/d' $CONF
        sed -i '/^save /d' $CONF
        echo "slaveof $VIP $REDISPORT" >> $CONF
        echo -e "save 900 1\nsave 300 10\nsave 60 10000" >> $CONF
        start
        ;;
    status)
        status -p ${PIDFILE} redis_${REDISPORT}
        ;;
    restart|reload)
        restart
        ;;
    truestart)
        start
        ;;
    truestop)
        stop
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac

