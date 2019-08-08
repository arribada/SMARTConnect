#!/bin/sh

# Exit when any command fails
#set -e

mkdir -p /home/smartConnect/filestore/dataqueue/
if [ $? -ne 0 ]; then
    >&2 echo "Couldn't create dataque folder"
    exit -1
fi

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	var="$1"
	val="$2"

    echo "Expanding $val secret into $var"
    ls $val # Stop execution if the file doesn't exist.
	export $var=$(cat $val)
}

file_env 'POSTGRES_USER' '/run/secrets/postgres-user'
file_env 'POSTGRES_PASS' '/run/secrets/postgres-pass'

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
    echo "Retrying..."
    sleep 1
done


export CATALINA_OPTS="-Dpostgres.hostname=${POSTGRES_HOSTNAME} -Dpostgres.port=${POSTGRES_PORT} -Dpostgres.user=${POSTGRES_USER} -Dpostgres.pass=${POSTGRES_PASS}"
catalina.sh run