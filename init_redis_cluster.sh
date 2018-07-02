#!/bin/sh

conf_path=/conf/redis.conf

if [ -n "${REDIS_PASSWD}" ]; then
    client_path=/var/lib/gems/2.3.0/gems/redis-3.3.5/lib/redis/client.rb
    sed -i "s/:password => nil/:password => '${REDIS_PASSWD}'/g" ${client_path}
fi


if [ -n "${REBUILDCLUSTER}" ]; then
    rm -rf /data/nodes.conf
fi

# run redis server
/usr/local/bin/redis-server /conf/redis.conf &


# wait redis to start
i=100
while [ $i -gt 0 ]
do
    proc_num=$(ps -ef | grep redis-server | grep -v "grep" | wc -l)
    if [ ${proc_num} -ne 0 ]; then
        break
    else
        echo >&1 'Redis init process in progress...' 
        sleep 3
    fi
    let i-=1
done

if [ "$i" = 0 ]; then
    echo >&2 'Redis init process failed.'
    exit 1
fi

for node in `echo "$REDIS_TRIB_PARA" | sed 's/ /\n/g'`
do  
    nodeip=`echo $node| cut -d : -f 1`
    nodeport=`echo $node| cut -d : -f 2`
    j=50
    while [ $j -gt 0 ]
    do
    		/usr/local/bin/redis-cli -p $nodeport -h $nodeip ping
    		if [ $? -ne 0 ]; then
    				echo >&2 'ping $nodeport $nodeip failed'
    				sleep 3
    		else
    				break
    		fi
    		let j-=1
    done
done





if [ -n "${MASTER}" ]; then
		echo "yes" | /usr/local/bin/redis-trib create --replicas ${REPLICAS_NUM} ${REDIS_TRIB_PARA}
fi

# keep the container at foreground
log_file=/data/redis.log
if [ ! -e ${log_file} ]; then
    touch ${log_file}
    chmod 777 ${log_file}
fi
tail -f ${log_file}
