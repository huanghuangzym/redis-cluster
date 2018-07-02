FROM redis
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update \
  && apt-get -y upgrade \
  && apt-get -y install procps net-tools \
  && apt-get -y install supervisor \
  && apt-get -y install vim \
  && apt-get -y --no-install-recommends install ruby wget \
  && gem install redis -v 3.3.5 \
  && apt-get -y autoremove \
  && apt-get -y clean
RUN wget -O /usr/local/bin/redis-trib http://download.redis.io/redis-stable/src/redis-trib.rb
RUN chmod 755 /usr/local/bin/redis-trib

# add shell script
COPY ./init_redis_cluster.sh /init_redis_cluster.sh
RUN chmod 755 /init_redis_cluster.sh

# add supervisord configuration
COPY ./supervisord.conf /etc/supervisord.conf

CMD redis-server
