#!/bin/bash

CONFIG_PATH="/etc/patchman/local_settings.py"

if [[ "$DBTYPE" != "mysql" ]] ; then
cat <<EOF > $CONFIG_PATH
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/var/lib/patchman/db/patchman.db'
    }
}

EOF
fi


cat <<EOF >> $CONFIG_PATH
ADMINS = (
    ('admin', 'admin@admin.com'),
)

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
RUN_GUNICORN = True
EOF

patchman-manage makemigrations
patchman-manage migrate --run-syncdb
patchman-manage collectstatic

cd /srv/patchman && gunicorn patchman.wsgi -b 0.0.0.0:80

