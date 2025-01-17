#!/bin/bash

chmod -R 755 /data/certs && find /data/certs -type f -exec chmod 644 {} \;
echo "Certificates are readable by everyone"
