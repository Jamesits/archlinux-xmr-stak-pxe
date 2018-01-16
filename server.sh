#!/bin/bash

sudo uwsgi --http 0.0.0.0:80 --wsgi-file pxe-server/server.py --callable __hug_wsgi__ --master --processes 4 --threads 2 --harakiri 1200
