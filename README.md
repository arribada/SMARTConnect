# TODO
 - auto generate ssl .keystore file.
 - don't expose db username and pass in the tomcat logs
 - server.war is too big to be kept in github so maybe build it from source. github has a limit of 100mb for a single file, but if build from source it will be broken into many small files.


# How to use

Install docker:
https://docs.docker.com/install/


Create postgres user and pass files in 
```
.local/postgres_user
.local/postgres_pass
```

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

Access smart connect at 
```
https://localhost:8443/server/connect/home
```

To check the application logs
```
docker service logs -f smart_tomcat
docker service logs -f smart_postgres
```

## Notes

The postgis image is created from https://github.com/appropriate/docker-postgis

With the following modifications to make it multi arch.
```
FROM --platform=$BUILDPLATFORM postgres:9.6
ENV POSTGIS_MAJOR 2.5
ENV POSTGIS_VERSION 2.5.2+dfsg-1~exp1.pgdg90+1
```
