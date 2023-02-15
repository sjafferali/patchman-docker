FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install curl git
RUN apt -y install python3-django python3-django-tagging python3-django-extensions \
    python3-djangorestframework python3-defusedxml python3-lxml python3-requests \
    python3-rpm python3-debian python3-colorama python3-humanize python3-magic \
    python3-pip python3-progressbar python3-gunicorn gunicorn python3-whitenoise \
    apache2 libapache2-mod-wsgi-py3

RUN pip3 install django-bootstrap3
RUN git clone https://github.com/furlongm/patchman /srv/patchman
RUN pip3 install -r /srv/patchman/requirements.txt
RUN mkdir -pv /etc/patchman /var/lib/patchman/db
RUN cd /srv/patchman && ./setup.py install
ADD entry.sh /entry.sh
RUN chmod 755 /entry.sh
RUN a2enmod wsgi && \
    cp /srv/patchman/etc/patchman/apache.conf.example /etc/apache2/conf-available/patchman.conf && \
    a2enconf patchman
RUN chown -R :www-data /etc/patchman && \
    chmod -R g+r /etc/patchman && \
    chown -R :www-data /var/lib/patchman && \
    chmod -R g+w /var/lib/patchman/db
ENTRYPOINT ["/entry.sh"]
