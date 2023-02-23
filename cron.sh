#!/usr/bin/env bash

while True ; do
    echo "sleeping for 86400 seconds"
    sleep 86400
    echo "performing repo updates"
    /usr/local/bin/patchman -a
done
