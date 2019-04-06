#!/bin/bash

# --------------------------------------------------------------------------
# constants
# --------------------------------------------------------------------------
RETURN_SUCCESS=0;
RETURN_ERROR=1;

# --------------------------------------------------------------------------
# check if not arguments are set, prints help
# --------------------------------------------------------------------------
if [[ $# -eq 0 || "$1" =  "help" || "$1" =  "--help" ]]
then
    echo "Usage: $0 [Options]";
    echo "setup";
    echo "reset-data";
    echo "up";
    echo "down";
    echo "logs";
    echo "grafana";
    echo "provisioning";
    echo "list";
    exit $RETURN_ERROR;
fi

# --------------------------------------------------------------------------
# check mandatory ARGS
# --------------------------------------------------------------------------
# Get ARGS into LINES, lowercase all strings
ARGS_LINES=$(echo $@ | tr " " "\n" | tr A-Z a-z);

#  check for options
SETUP=0;
if [[ $(echo $ARGS_LINES | grep "setup") ]]
then
    echo "Option: setup [ACTIVE]";
    SETUP=1;
fi

RESET_DATA=0;
if [[ $(echo $ARGS_LINES | grep "reset-data") ]]
then
    echo "Option: reset-data [ACTIVE]";
    RESET_DATA=1;
fi

SERVICE_UP=0;
if [[ $(echo $ARGS_LINES | grep "up") ]]
then
    echo "Option: up [ACTIVE]";
    SERVICE_UP=1;
fi

SERVICE_DOWN=0;
if [[ $(echo $ARGS_LINES | grep "down") ]]
then
    echo "Option: down [ACTIVE]";
    SERVICE_DOWN=1;
fi

LOGS=0;
if [[ $(echo $ARGS_LINES | grep "logs") ]]
then
    echo "Option: logs [ACTIVE]";
    LOGS=1;
fi

GRAFANA=0;
if [[ $(echo $ARGS_LINES | grep "grafana") ]]
then
    echo "Option: grafana [ACTIVE]";
    GRAFANA=1;
fi

PROVISIONING=0;
if [[ $(echo $ARGS_LINES | grep "provisioning") ]]
then
    echo "Option: provisioning [ACTIVE]";
    PROVISIONING=1;
fi

LIST=0;
if [[ $(echo $ARGS_LINES | grep "list") ]]
then
    echo "Option: list [ACTIVE]";
    LIST=1;
fi
# --------------------------------------------------------------------------


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------
# list services
if [[ "$LIST" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "List";
    echo "------------------------------------------------------------";
    docker-compose -f docker-compose.yml ps;
fi

# reset-data
if [[ "$RESET_DATA" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Reset Data";
    echo "------------------------------------------------------------";
    read -p "Do you want to delete InfluxDB and Grafana local \"data\" (y/n)?" yn;
    case $yn in
        [Yy]* ) docker-compose down;
                rm -rf data/grafana/*;
                rm -rf data/influxdb/*;
                exit $RETURN_SUCCESS;
            ;;
        [Nn]* ) exit $RETURN_ERROR;;
    esac
fi

# setup
if [[ "$SETUP" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Setup";
    echo "------------------------------------------------------------";
fi

# provisioning
if [[ "$PROVISIONING" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "Grafana Provisioning";
    echo "------------------------------------------------------------";
#        --user "1000" \
    docker run -d \
        --volume "$PWD/data/grafana:/var/lib/grafana" \
        --volume "$PWD/grafana/conf/provisioning/:/etc/grafana/provisioning/" \
        --env-file "$PWD/grafana/env/env.grafana" \
        --name grafana_provisioning \
        --rm grafana/grafana:latest;

    # wait for grafana to terminate provisioning procedure
    docker logs -f grafana_provisioning | {
        while IFS= read -r logline
        do
            echo "$logline";
            if [[ "$logline" =~ ^.*HTTP[[:space:]]Server[[:space:]]Listen.*$ ]]
            then
                echo "Grafana provisioning procedure completed";
                break;
            fi;
        done;
    }
    docker stop grafana_provisioning;
    # need to remove the imported dashboards from the sqlite3 grafana.db database
    # in order for the user to be able to edit and save in the normal way
    echo "Opening Grafana.db sqlite3 database to delete \"dashboard_provisioning\" data (will allow user to edit/save imported Dashboards)";
    docker run \
        --volume "$PWD/data/grafana/grafana.db:/grafana.db" \
        --rm -it nouchka/sqlite3 /grafana.db 'DELETE FROM `dashboard_provisioning` WHERE id>0;';
fi

# docker-compose up
if [[ "$SERVICE_UP" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[UP] Running services";
    echo "------------------------------------------------------------";
    docker-compose up -d;
fi

# open grafana
if [[ "$GRAFANA" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[GRAFANA] Open grafana"
    echo "------------------------------------------------------------";

    printf "Waiting for grafana PORT to be available ";
    while [ $(nc -zvn 127.0.0.1 3000 &>/dev/null && echo "1" || echo "0") -eq 0 ]
    do
        printf ".";
        sleep 1;
    done
    echo "";

    printf "Waiting for grafana HTTP response ";
    while [ $(curl --silent http://localhost:3000 &>/dev/null && echo "1" || echo "0") -eq 0 ]
    do
        printf ".";
        sleep 1;
    done
    echo "";

    open http://localhost:3000;
fi

# docker-compose logs
if [[ "$LOGS" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[LOGS] Attach to services logs";
    echo "------------------------------------------------------------";
    docker-compose logs -f;
fi

# docker-compose down
if [[ "$SERVICE_DOWN" = "1" ]]
then
    echo "------------------------------------------------------------";
    echo "[DOWN] Shuting down services";
    echo "------------------------------------------------------------";
    # stop all docker services
    docker-compose down;
fi
# --------------------------------------------------------------------------

exit $RETURN_SUCCESS;