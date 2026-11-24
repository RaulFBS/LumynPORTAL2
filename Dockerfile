FROM tomcat:10.1-jdk21-temurin

WORKDIR /app
COPY web /usr/local/tomcat/webapps/ROOT
COPY dist/LumynPortalWeb2.war /tmp/base.war
COPY src/java /app/src

RUN rm -rf /usr/local/tomcat/webapps/examples /usr/local/tomcat/webapps/docs /usr/local/tomcat/webapps/manager /usr/local/tomcat/webapps/host-manager \
    && mkdir -p /usr/local/tomcat/webapps/ROOT/WEB-INF/lib /usr/local/tomcat/webapps/ROOT/WEB-INF/classes \
    && cd /tmp && jar xf /tmp/base.war WEB-INF/lib \
    && cp /tmp/WEB-INF/lib/*.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/ \
    && rm -rf /tmp/base.war /tmp/WEB-INF \
    && find /app/src -name "*.java" > /app/sources.txt \
    && javac -encoding UTF-8 -cp "/usr/local/tomcat/lib/*:/usr/local/tomcat/webapps/ROOT/WEB-INF/lib/*" -d /usr/local/tomcat/webapps/ROOT/WEB-INF/classes @/app/sources.txt \
    && rm -rf /app

EXPOSE 8080

CMD ["catalina.sh", "run"]
