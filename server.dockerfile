FROM node:alpine

RUN apk add --no-cache \
  curl \
  openjdk8 \  
  subversion


COPY . /opt/fair/

WORKDIR /opt/fair

CMD /opt/fair/run-docker.sh

# manually:
# docker build -t fairlanguage-server -f server.dockerfile ./
# docker run --name fairlanguage-server -d -p 1049:1049 fairlanguage-server
