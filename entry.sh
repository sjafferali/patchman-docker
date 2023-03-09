#!/bin/bash

CONFIG_PATH="/etc/patchman/local_settings.py"

setup_database () {
    case $DB_TYPE in
        "mysql")
            cat <<EOF > $CONFIG_PATH
DATABASES = {
   'default': {
       'ENGINE': 'django.db.backends.mysql',
       'NAME': '${DB_NAME}',
       'USER': '${DB_USER}',
       'PASSWORD': '${DB_PASS}',
       'HOST': '${DB_HOST}',
       'PORT': '${DB_PORT}',
       'STORAGE_ENGINE': 'INNODB',
       'CHARSET' : 'utf8'
   }
}
EOF
        ;;
        "pgsql")
            cat <<EOF > $CONFIG_PATH
DATABASES = {
   'default': {
       'ENGINE': 'django.db.backends.postgresql_psycopg2',
       'NAME': '${DB_NAME}',
       'USER': '${DB_USER}',
       'PASSWORD': '${DB_PASS}',
       'HOST': '${DB_HOST}',
       'PORT': '${DB_PORT}',
       'CHARSET' : 'utf8'
   }
}
EOF
        ;;
        *)
            cat <<EOF > $CONFIG_PATH
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/var/lib/patchman/db/patchman.db'
    }
}
EOF
        ;;
    esac
}


setup_database

cat <<EOF >> $CONFIG_PATH
ADMINS = (
    ('${ADMIN_USER}', '${ADMIN_EMAIL}'),
)

USE_ASYNC_PROCESSING = True

TIME_ZONE = '${TZ}'

LANGUAGE_CODE = 'en-us'

# Create a unique string here, and don't share it with anybody.
SECRET_KEY = '${SECRET_KEY}'

# Add the IP addresses that your web server will be listening on,
# instead of '*'
ALLOWED_HOSTS = ['127.0.0.1', '*']

# Maximum number of mirrors to add or refresh per repo
MAX_MIRRORS = 5

# Number of days to wait before notifying users that a host has not reported
DAYS_WITHOUT_REPORT = 14

# Whether to run patchman under the gunicorn web server
RUN_GUNICORN = False


CACHES = {
   'default': {
       'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
       'LOCATION': '${MEMCACHED_LOCATION}',
   }
}
EOF

patchman-manage makemigrations
patchman-manage migrate --run-syncdb
patchman-manage collectstatic

cp -f /srv/patchman/etc/patchman/apache.conf.example /etc/apache2/conf-available/patchman.conf
for str in ${REPORT_HOSTS//,/ } ; do
    sed -i "s,Require ip ::1/128,&\n    Require ip $str," /etc/apache2/conf-available/patchman.conf
done

if [[ "$OPENID_AUTH" == "1" ]]; then
cat <<EOF >> /etc/apache2/conf-available/patchman.conf
OIDCProviderMetadataURL ${OIDCProviderMetadataURL}
OIDCClientID ${OIDCClientID}
OIDCClientSecret ${OIDCClientSecret}

# OIDCRedirectURI is a vanity URL that must point to a path protected by this module but must NOT point to any content
OIDCRedirectURI ${OIDCRedirectURI}
OIDCCryptoPassphrase ${OIDCCryptoPassphrase}
OIDCScope "${OIDCScope}"
OIDCRemoteUserClaim ${OIDCRemoteUserClaim}


<Location /patchman/reports/upload>
    Order deny,allow
    Allow from all
    Satisfy any
</Location>

<Location /patchman>
   AuthType openid-connect
   Require valid-user
</Location>
EOF

cat <<EOF >> $CONFIG_PATH

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.cache.UpdateCacheMiddleware',
    'django.middleware.http.ConditionalGetMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.auth.middleware.RemoteUserMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'django.middleware.cache.FetchFromCacheMiddleware',
]

AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.RemoteUserBackend',
    'django.contrib.auth.backends.ModelBackend'
]

EOF

fi

a2enconf patchman

mkdir -pv /var/lib/patchman/static/
rsync -avz /usr/share/patchman/static/ /var/lib/patchman/static/
rsync -avz /usr/lib/python3/dist-packages/django/contrib/admin/static/ /var/lib/patchman/static/
chown -Rv :www-data /etc/patchman
chmod -R g+rw /etc/patchman
chown -R :www-data /var/lib/patchman
chmod -R g+rw /var/lib/patchman/

export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
export APACHE_LOG_DIR=/var/log/apache2

service redis-server restart
C_FORCE_ROOT=1 celery -b redis://127.0.0.1:6379/0 -A patchman worker -l INFO -E &

/cron.sh &

apachectl -D FOREGROUND
