#!/bin/sh

# Exit when any command fails
#set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	var="$1"
	val="$2"

    echo "Expanding $val secret into $var"
	export $var=$(cat $val)
}

#  Docker secrets take precedence.
if [ -n "$POSTGRES_USER_FILE" ] ; then
    echo "POSTGRES_USER_FILE env provided so using it is a secret"
    file_env 'POSTGRES_USER' '/run/secrets/postgres-user'
fi

if [ -n "$POSTGRES_PASSWORD_FILE" ] ; then
    echo "POSTGRES_PASSWORD_FILE env provided so using it is a secret"
    file_env 'POSTGRES_PASSWORD' '/run/secrets/postgres-pass'
fi

if [ -z "$POSTGRES_USER" ]  || [ -z "$POSTGRES_PASSWORD" ] ; then
    echo "no POSTGRES_USER or POSTGRES_PASSWORD provided as an env or docker secret"
    exit 1 # terminate and indicate error
fi

echo "Testing db connection to host:$POSTGRES_HOSTNAME:$POSTGRES_PORT."
MAX_RETRY=480
count=0
while :
do
    count=$((count+1))
    nc -z $POSTGRES_HOSTNAME $POSTGRES_PORT
    if [ $? -eq 0 ]; then
        echo "Connection is available after $count second(s)."
        break
    fi
    if [ $count -eq $MAX_RETRY ]; then
        >&2 echo "No connection after $MAX_RETRY seconds"
        exit 1
    fi
    echo "Retrying db connection host:$POSTGRES_HOSTNAME port:$POSTGRES_PORT ..."
    sleep 1
done


mkdir -p /home/SMARTconnect/filestore/dataqueue/
if [ $? -ne 0 ]; then
    >&2 echo "Couldn't create dataque folder"
    exit -1
fi


export CATALINA_OPTS="-Dpostgres.hostname=${POSTGRES_HOSTNAME} -Dpostgres.port=${POSTGRES_PORT} -Dpostgres.user=${POSTGRES_USER} -Dpostgres.pass=${POSTGRES_PASSWORD}"
catalina.sh run