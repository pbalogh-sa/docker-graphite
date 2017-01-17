FROM ubuntu:16.04
MAINTAINER Peter Balogh <p.balogh.sa@gmail.com>

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && \
    apt-get -y install \
    graphite-web \
    graphite-carbon \
    apache2 \
    libapache2-mod-wsgi \
    apt-get -y autoremove && \
    apt-get -y autoclean && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*

RUN sed -i "s/#SECRET_KEY.*/SECRET_KEY = 'poke_secret'/g" /etc/graphite/local_settings.py
RUN graphite-manage syncdb --noinput
RUN sed -i 's/CARBON_CACHE_ENABLED.*/CARBON_CACHE_ENABLED=true/g' /etc/default/graphite-carbon
RUN sed -i 's/ENABLE_LOGROTATION.*/ENABLE_LOGROTATION = True/g' /etc/carbon/carbon.conf
RUN a2dissite 000-default
RUN cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available
RUN a2ensite apache2-graphite
RUN chown _graphite /var/lib/graphite/graphite.db

ADD services/apache /etc/services.d/apache/run
ADD services/carbon /etc/services.d/carbon/run

VOLUME /etc/carbon /etc/graphite /var/lib/graphite/whisper
EXPOSE 80 2003 2004 7002

ENTRYPOINT ["/init"]
