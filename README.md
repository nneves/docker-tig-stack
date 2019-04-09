# [TIG] Telegram + InfluxDB + Grafana

## TL;DR

long story short:
* initial setup

```bash
./tig.sh config
./tig.sh provisioning
```

* launch

```bash
./tig.sh up
```

* terminate

```bash
./tig.sh down
```

* list services

```bash
./tig.sh list
```

* attach to logs

```bash
./tig.sh logs
```

* open Grafana UI (waits for the service to be responsive)

```bash
./tig.sh grafana
```

* *Local development command*

```bash
./tig.sh up grafana logs down
```
Hit CTRL+C to exist logs, down command should still run.

## Complete walkthrough

[TIG] Telegram + InfluxDB + Grafana Stack basic setup to collect metrics on a Linux server:

* Telegraf: data collector
* IngluxDB: timeseries database
* Grafana: data visualization

### 1. Initial setup

Current setup defines Grafana `GF_SECURITY_ADMIN_PASSWORD` in the `grafana/env/env.grafana` file. It is advise to change the current password using the command: 

```bash
./tig.sh config
```

The above command can run at different levels of the project, initial stage were no database or data exists, after Grafana `provisioning` stage or even during the normal usage with Grafana running.

### 2. Grafana provisioning

Grafana is configured to use an SQLite database in `data/grafana/grafana.db`. The database file is not included in the current repo (it's not a good practice, will tend to grown in time, it's a binary data file, can overwrite your existing database if you decide to pull updates).

The above initial setup will assist creating the Grafana database and setting up the admin password (it's also a good practice to use a different one from the repo default value), but it will launch Grafana without the required `Datasource` and pre-configured `Dashboards`.

There are some documentation explaining how to use Grafana REST API to create such resources, but also, there is the `gitops` approach with the Grafana provisioning capability: https://grafana.com/docs/administration/provisioning/

Well, for the current project it makes sense to import the resources during the initial setup, and after it will detach the provisioning pattern to use the standard mode (imported Datasource and Dashboards can be edited and saved directly into Grafana database). It's still advised to export your Dashboards from time to time (or even commit then to the repo `grafana/conf/provisioning/dashboards`).

```bash
./tig.sh provisioning
```

### 3. Launch the TIG stack

After getting Grafana properly setup and provisioned (point .1 and .2), it's now possible to launch our full TIG stack with the command:

```bash
./tig.sh up
```

The current project is defined to only expose Grafana UI to port `3000`, so you should be able to open a browser with your *\<Server URL\>:3000* or *\<IP address\>:3000* (check the docker-compose.yml, if you need to change the host port of Grafana please adjust the port parameter: e.g.: expose Grafana on host port 80 => `"80:3000"`).

Please note that it takes a few minutes for Grafana and all the other services to be stable.

To terminate the TIG stack, run the command:

```bash
./tig.sh down
```

### 4. tig.sh helper script options

In order to simply the docker-compose commands there is a `tig.sh` bash script helper with a few built-in command options. Note that the options argument position is arbitrary and can be switched, the script will make sure that some more important steps run first.

```bash
./tig.sh config         # configures grafana.db admin password: GF_SECURITY_ADMIN_PASSWORD
./tig.sh reset-data     # completely removes InfluxDB and Grafana data (use with caution, no way back from here)
./tig.sh up             # launches the services: similar to `docker-compose up`
./tig.sh down           # terminates the services: similar to `docker-compose down`
./tig.sh logs           # attach to docker-compose logs (tail -f)
./tig.sh grafana        # waits for the grafana service respond, opens the URL in the browser
./tig.sh provisioning   # initialize the grafana.db with the Datasource and Dashboards committed in the repo
./tig.sh list           # lists the services: similar to docker-compose ps
```