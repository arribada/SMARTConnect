FROM tomcat:8.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY server.war /usr/local/tomcat/webapps/
COPY server.xml /usr/local/tomcat/conf/
COPY jar_files/* /usr/local/tomcat/lib/
COPY entrypoint.sh ./
COPY .keystore /root/
RUN chmod +x entrypoint.sh
CMD ["./entrypoint.sh"]
