# Homebrew Visualization Engine

## Introduction
Automation which installs and configures Grafana and InfluxDB on the local Raspbian system. 

## How to use
You can execute the shell script with the following options:
- -p or --password to set the admin password for Grafana. For security reasons, this is ***mandatory***. Example: -p 12345
- -d or --database to set the InfluxDB database name, if not set the default name will be used (homebrew). Example: -d BakerStreet
- -s or --datasource to set the Grafana datasource name, if not set the default name will be used (InfluxDB). Example: -s Gerry

It's important to use sudo rights when executing the script, because of the installation process.

Example: 
>  sudo ./visualization_engine.sh -p test123