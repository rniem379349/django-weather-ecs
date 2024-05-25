#!/bin/sh
set -e

python manage.py collectstatic --noinput
python manage.py migrate --noinput
gunicorn --chdir /app -c /app/gunicorn/gunicorn_config.py djangoweather.wsgi:application
