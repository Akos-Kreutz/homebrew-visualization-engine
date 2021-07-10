#!/bin/bash

error_file="homebrew_dashboard.out"

error() {
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${1}"
  echo -e "${timestamp} - ${1}" >> "homebrew_dashboard.out"
  exit 1
}

usage() {
  echo "Use -p or --password to set the admin password for Grafana. For security reasons this is mandatory. Example: -p 12345"
  echo "Use -d or --database to set the InfluxDB database name, if not set the default name will be used (homebrew). Example: -d BakerStreet"
  echo "Use -s or --datasource to set the Grafana datasource name, if not set the default name will be used (homebrew). Example: -d BakerStreet"
  exit 2
}

while [ "$1" != "" ]; do
  case $1 in
    -d | --database )
      shift
      database=$1
      ;;
    -p | --password )
      shift
      password=$1
      ;;
    -s | --datasource )
      shift
      datasource=$1
      ;;
    -h | --help )
      usage
      ;;
    * )
      usage
      ;;
  esac
  shift
done

if [ -z ${password+x} ]; then
  error "Please set the new password for the Grafana admin user."
fi

if [ ${#password} -lt 5 ]; then
  error "Grafna only accepts password which is five or more characters."
fi

if [ -z ${database+x} ]; then
  database="homebrew"
fi

if [ -z ${datasource+x} ]; then
  database="homebrew"
fi

echo "Installing Prerequisites"
apt update
output=$(apt -y install python3 python3-pip python-apt wget curl 2>&1 > /dev/null)

if [[ $? -ne 0 ]]; then
  error "Unable to install prerequisites.\n${output}"
fi

echo "Adding InfluxDB Repository Key"
output=$(wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add - 2>&1 > /dev/null)

if [[ $? -ne 0 ]]; then
  error "Unable to add InfluxDB Repository Key.\n${output}"
fi

echo "Adding Grafana Repository Key"
output=$(wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add - 2>&1 > /dev/null)

if [[ $? -ne 0 ]]; then
  error "Unable to add Grafana Repository Key.\n${output}"
fi

echo "Adding InfluxDB Repository to the source list"
output=$(echo "deb https://repos.influxdata.com/debian buster stable" | sudo tee /etc/apt/sources.list.d/influxdb.list 2>&1 > /dev/null)

if [[ $? -ne 0 ]]; then
  error "Unable to add InfluxDB Repository to the source list.\n${output}"
fi

echo "Adding Grafana Repository to the source list"
output=$(echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list)

if [[ $? -ne 0 ]]; then
  error "Unable to add Grafana Repository to the source list.\n${output}"
fi

echo "Installing InfluxDB & Grafana"
apt update
output=$(apt -y install influxdb grafana)

if [[ $? -ne 0 ]]; then
  error "Unable to install InfluxDB & Grafana.\n${output}"
fi

echo "Enabling InfluxDB & Grafana Services"

systemctl unmask influxdb
systemctl enable influxdb
systemctl start influxdb

systemctl enable grafana-server
systemctl start grafana-server

echo "Installing Python Modules"
output=$(pip3 install influxdb)

if [[ $? -ne 0 ]]; then
  error "Unable to install python modules.\n${output}"
fi

echo "Starting Python Script"
chmod +x visualization_engine.py
python3 ./visualization_engine.py -d "${database}" -s "${datasource}"

echo "Changing admin user password"
output=$(curl -s -X PUT -H "Content-Type: application/json" -d '{
  "oldPassword": "admin",
  "newPassword": "'"${password}"'",
  "confirmNew": "'"${password}"'"
}' http://admin:admin@localhost:3000/api/user/password)

if [[ $? -ne 0 ]]; then
  error "Unable to change Grafana admin user password.\n${output}"
fi
