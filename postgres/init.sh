#!/bin/bash
if [ -d "/var/lib/postgresql/data" ] && [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
    initdb -D /var/lib/postgresql/data
fi