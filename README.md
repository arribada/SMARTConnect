# TODO
 - auto generate ssl .keystore file.
 - don't expose db username and pass in the tomcat logs
 - server.war is too big to be kept in github so maybe build it from source. github has a limit of 100mb for a single file, but if build from source it will be broken into many small files. At the moment the server.war file is added as a release and downloaded from the CI.


# How to use

Install docker:
https://docs.docker.com/install/

## Run using docker swarm
### Note
The docker swarm networking is broken for the Rpi 4 and
docker-compose also doesn't install properly there so
need to run the containers using docker run with the instructions below.

To be able to deploy services using `docker stack deploy` and avoid installing docker compose need to enable swarm mode. 
This also allows rolling updates.

```
docker swarm init
```
Deploy the application.
> This will take a while the first time as it needs to download all docker images.
```
git clone  https://github.com/arribada/SMARTConnect.git
cd SMARTConnect
mkdir .local
echo "postgres" > .local/postgres_user 
echo "postgres" > .local/postgres_pass
docker stack deploy -c docker-compose.yml smart
```

Check the status.
> Once the `Replicas` column shows `1/1` the application has been deployed.
```
docker stack services smart
```

## Run using docker run
```
docker network create smart
docker run -d \
    --name=tomcat \
    --net=smart \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_PORT=5432 \
    -e POSTGRES_HOSTNAME=postgres \
    -v tomcat:/home/SMARTconnect/filestore/ \
    -p 8443:8443 \
    arribada/smart-connect:v0.0.1

docker run -d \
    --net=smart \
    --name=postgres \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -v postgres:/var/lib/postgresql/data \
    arribada/smart-connect-postgis:v0.0.1
```

Check the logs
```
docker logs -f tomcat
docker logs -f postgres
```

Access smart connect at 
```
https://localhost:8443/server/connect/home
```

To check the application logs
```
docker service logs -f smart_tomcat
docker service logs -f smart_postgres
```

NOTES:
to trigger a new image build an push with circle, just create a new tag or delete and recreate an existing tag.


## Configuring SMART Desktop to access the Server

Additional steps must now be taken in order for a SMART Desktop installation to be able to access the server.

The certificate to be used when configuring SMART Desktop to access the server is found at [tomcat/ssl.cert](tomcat/ssl.cert)

Additionally, in order to use this certificate you must add an alias to your host file so that the IP address of the hosting machine is usable with the certificate.


Edit the system host file to link the certificate hostname to the correct IP
C:\Windows\System32\drivers\etc\hosts
Append the following two lines to the file

```
#SMARTCONNECT
<IP.Of.Hosting.Machine> smartconnect
```

At this point, you will be able to connect SMART desktop to `https://smartconnect:8443/server` with the provided certificate file and the default smart:smart login credentials. 
