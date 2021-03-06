#!/bin/bash -e

if [ -z "$1" ]; then
    echo
    echo "Django project starter"
    echo "-----------------------"
    echo "Run with source to switch the virtualenv and set required environment variables."
    echo
    echo "Usage: "
    echo
    echo "$ source ./run-project.sh [shell|setenv|dev|console|production] [--log-level=debug|critical]"
    echo
    echo "Parameters:"
    echo "- shell: Django shell."
    echo "- setenv: Sets environment to use django-admin.py commands."
    echo "- dev: Django development server"
    echo "- console: start Django with Nginx/Gunicorn with logging to console."
    echo "- production --log-level=LOGLEVEL: Django with Nginx/Gunicorn and logging. Called from Upstart service."
    echo
else
    export PROJECT_RUNNING_DEV=""
    {% set db_engine = salt['pillar.get']('postgres:lookup:db_engine', '') -%}
    {% set dummy_db = salt['pillar.get']('postgres:lookup:dummy_db', '') -%}
    {% if db_engine == 'sqlite3' -%}
    export PROJECT_DATABASES_ENGINE="sqlite3"
    export PROJECT_DATABASES_DEFAULT_NAME="{{ dummy_db }}"
    {% else -%}
    {% for db_name, db_values in salt['pillar.get']('postgres:databases', []).items() -%}
    export PROJECT_DATABASES_ENGINE="postgresql"
    export PROJECT_DATABASES_DEFAULT_NAME="{{ db_name }}"
    export PROJECT_DATABASES_DEFAULT_USER="{{ db_values.user }}"
    {% for user_name, user_values in salt['pillar.get']('postgres:users', []).items() -%}
    {% if user_name == db_values.user -%}
    export PROJECT_DATABASES_DEFAULT_PASSWORD="{{ user_values.password }}"
    {% endif -%}
    {% endfor -%}
    {% endfor -%}
    {% for id, postgresql_server in salt['pillar.get']('zinibu_basic:project:postgresql_servers', {}).iteritems() %}
    export PROJECT_DATABASES_DEFAULT_HOST="{{ postgresql_server.private_ip }}"
    export PROJECT_DATABASES_DEFAULT_PORT="{{ postgresql_server.port }}"
    {% endfor -%}
    {% endif -%}
    
    {% for id, redis_node in salt['pillar.get']('zinibu_basic:project:redis_nodes', {}).iteritems() %}
    export PROJECT_REDIS_HOST="{{ redis_node.private_ip }}"
    export PROJECT_REDIS_PORT="{{ redis_node.port }}"
    {% endfor -%}
    
    # user/group to run as
    USER={{ user }}
    GROUP={{ group }}
    export HOME="/home/$USER"
    
    # PROJECTNAME is used by the Python virtual environment, the Django project and the log file.
    PROJECTNAME={{ project_name }}
    PROJECTDIR=/home/$USER/$PROJECTNAME
    PROJECTENV=/home/$USER/pyvenvs/$PROJECTNAME
    {% if salt['pillar.get']('zinibu_django_env', '') != '' -%}
    {% set django_env = salt['pillar.get']('zinibu_django_env') -%}
    {% else -%}
    {% from "zinibu/map.jinja" import django with context %}
    {% set django_env = django.env -%}
    {% endif -%}
    export DJANGO_SETTINGS_MODULE=$PROJECTNAME.settings.{{ django_env }}
    
    NUM_WORKERS=3
    BIND_ADDRESS={{ private_ip }}:{{ gunicorn_port }}
    BIND_ADDRESS_DEV={{ public_ip }}:8000
    
    source $PROJECTENV/bin/activate
    
    cd $PROJECTDIR
    export LC_ALL="en_US.UTF-8"
    
    if [ "$1" == "dev" ]; then
      # development server
      # no need for calling python first for django-admin.py
      echo "==================================="
      echo "Django development server"
      echo "==================================="
      # Using DJANGO_SETTINGS_MODULE environment variables as we are not specifying --settings
      #django-admin.py runserver --pythonpath=`pwd` --settings=$PROJECTNAME.settings $BIND_ADDRESS
      PROJECT_RUNNING_DEV=true
      django-admin.py runserver --pythonpath=`pwd` $BIND_ADDRESS_DEV
      # thin wrapper for django-admin.py, no need for --pythonpath or --settings but it requires to use python first
      #python manage.py runserver $BIND_ADDRESS
    elif [ "$1" == "update_index" ]; then
      django-admin.py update_index --age=$2 --pythonpath=`pwd`
    elif [ "$1" == "shell" ]; then
      django-admin.py shell --pythonpath=`pwd`
    elif [ "$1" == "setenv" ]; then
      echo "==================================="
      echo "Done! The environment variables have been set to run the $PROJECTNAME project."
      echo "You can now run any django-admin.py command from $PROJECTDIR (note the use of --pythonpath with pwd to get the working directory):"
      echo "django-admin.py shell --pythonpath=\`pwd\`"
      echo
      echo "Or, to avoid backticks:"
      echo "django-admin.py shell --pythonpath=\$(pwd)"
      echo "==================================="
    elif [ "$1" == "production" ]; then
      # production server (gunicorn)
      # see http://docs.gunicorn.org/en/latest/settings.html#loglevel
      # possible values: debug, info, warning, error, critical

      LOGFILE=/var/log/upstart/$PROJECTNAME.log
      # logging inside /var/log/upstart, the directory should already be present
      LOGDIR=$(dirname $LOGFILE)
      test -d $LOGDIR || mkdir -p $LOGDIR

      if [ "$2" == "--log-level=debug" ]; then
        LOGLEVEL=debug
      elif [ "$2" == "--log-level=critical" ]; then
        LOGLEVEL=critical
      else
        LOGLEVEL=info
      fi
      gunicorn --workers=$NUM_WORKERS --user=$USER --group=$GROUP --bind $BIND_ADDRESS $PROJECTNAME.wsgi:application --log-level=$LOGLEVEL --log-file=$LOGFILE 2>>$LOGFILE
      # I don't think exec is important anymore here to keep environment variables when running any of the commands with upstart
      #exec gunicorn --workers=$NUM_WORKERS --user=$USER --group=$GROUP --bind $BIND_ADDRESS $PROJECTNAME.wsgi:application --log-level=$LOGLEVEL --log-file=$LOGFILE 2>>$LOGFILE
    elif [ "$1" == "collectstatic" ]; then
      echo "==================================="
      echo "Django collect static files"
      echo "==================================="
      #django-admin.py collectstatic --pythonpath=`pwd` --settings=$PROJECTNAME.settings --noinput
      # Using DJANGO_SETTINGS_MODULE environment variables as we are not specifying --settings
      django-admin.py collectstatic --pythonpath=`pwd` --noinput
    elif [ "$1" == "console" ]; then
      ## production server (gunicorn) with log to console
      echo "==================================="
      echo "Gunicorn with log to console"
      echo "==================================="
      gunicorn --workers=$NUM_WORKERS --user=$USER --group=$GROUP --bind $BIND_ADDRESS $PROJECTNAME.wsgi:application
    else
      echo
      echo "==================================="
      echo "Invalid parameter. Run without parameters for help."
      echo "==================================="
      echo
    fi
fi
