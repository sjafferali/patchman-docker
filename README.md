# Patchman Docker

[![Pulls from DockerHub](https://img.shields.io/docker/pulls/sjafferali/patchman.svg)](https://hub.docker.com/r/sjafferali/patchman)
[![latest version](https://img.shields.io/github/tag/sjafferali/patchman.svg)](https://github.com/sjafferali/patchman/releases)

A docker container for https://github.com/furlongm/patchman . 

# Usage
## Compose Files
### Sqlite Example
```
version: '3'
services:
  patchman:
    container_name: patchman
    image: sjafferali/patchman:latest
    environment:
      TZ: America/Los_Angeles
      DB_TYPE: sqlite
      SECRET_KEY: ${SECRET_KEY}
      REPORT_HOSTS: 0.0.0.0/0
    expose:
      - 80
    volumes:
      - db:/var/lib/patchman/db
    restart: unless-stopped
volumes:
  db:
```

### MySQL Example
```
version: '3'
services:
  patchman:
    container_name: patchman
    image: sjafferali/patchman:latest
    environment:
      TZ: America/Los_Angeles
      SECRET_KEY: ${SECRET_KEY}
      REPORT_HOSTS: 0.0.0.0/0
      DB_TYPE: mysql
      DB_HOST: db
      DB_USER: ${DB_USER}
      DB_PASS: ${DB_PASS}
      DB_NAME: ${DB_NAME}
      MEMCACHED_LOCATION: cachedb:11211
    expose:
      - 80
    restart: unless-stopped
  db:
    container_name: patchman-db
    image: mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: ${DBROOTPASS}
      MYSQL_ROOT_USER: root
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASS}
      MARIADB_MYSQL_LOCALHOST_USER: "true"
    restart: unless-stopped
    volumes:
      - db:/var/lib/mysql
    restart: unless-stopped
  cachedb:
    container_name: patchman-memcached
    image: memcached:latest
    restart: unless-stopped
volumes:
  db:
```

## Initial Admin User Setup
To create the initial administrator user, login to the container and execute the below command. 
```
patchman-manage createsuperuser
```
