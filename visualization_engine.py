from influxdb import InfluxDBClient
from requests.auth import HTTPBasicAuth
import getopt, sys, requests, datetime, json

database_name = 'homebrew'
datasource_name = 'homebrew'
influxdb_port = 8086
influxdb_host = 'localhost'
short_options = 'd:s:h'
long_options = ['database=', 'datasource=', 'help']

def error(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(message)
    file = open("homebrew_dashboard.out", "a+")
    file.write(timestamp, " " , message)
    sys.exit(1)

def changeValueInJson(file_name, key, value):
  file = open(file_name, "r")
  data = json.load(file)
  file.close
  data[key] = value
  file = open(file_name, "w")
  json.dump(data, file)
  file.close

def replaceInFile(file_name, old, new):
  with open(file_name) as file:
    newText = file.read().replace(old, new)

  with open(file_name, "w") as file:
      file.write(newText)

try:
    arguments, values = getopt.getopt(sys.argv[1:], short_options, long_options)
except getopt.error as err:
    error(str(err))

for current_argument, current_value in arguments:
    if current_argument in ('-d', '--database'):
        database_name = current_value
        changeValueInJson("datasource.json", "database", database_name)
    if current_argument in ('-s', '--datasource'):
        datasource_name = current_value
        changeValueInJson("datasource.json", "name", datasource_name)
        replaceInFile("dashboard.json", "\"datasource\":\"InfluxDB\"", "\"datasource\":\"{datasource_name}\"")
    elif current_argument in ('-h', '--help'):
        print("Use -d or --database to set the InfluxDB database name, if not set the default name will be used (homebrew). Example: -d BakerStreet")
        print("Use -s or --datasource to set the Grafana datasource name, if not set the default name will be used (homebrew). Example: -d BakerStreet")
        exit(2)

try:
    print('Connecting to InfluxDB on host: ', influxdb_host, ' port: ', influxdb_port)
    client = InfluxDBClient(influxdb_host, influxdb_port)

    database_exists = False
    for db in client.get_list_database():
      if db.get('name')  ==  database_name:
        database_exists = True
        break

    if database_exists:
        print('Database already exists with name: ', database_name)
    else :
        print('Creating InfluxDB database with name: ', database_name)
        client.create_database(database_name)

    
    url = 'http://localhost:3000/api/datasources'
    headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
    r = requests.get(url, auth=HTTPBasicAuth('admin', 'admin'), headers=headers)

    if (str(r).count("\"name\":\"{datasource_name}\"") > 0):
      print("DataSource already exists")
    else:
      print('Creating Grafana DataSource')
      url = 'http://localhost:3000/api/datasources'
      headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
      r = requests.post(url, auth=HTTPBasicAuth('admin', 'admin'), data=open('datasource.json', 'rb'), headers=headers)

    print('Creating Grafana Dashboard')
    url = 'http://localhost:3000/api/dashboards/import'
    headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
    r = requests.post(url, auth=HTTPBasicAuth('admin', 'admin'), data=open('dashboard.json', 'rb'), headers=headers)
except getopt.error as err:
  error(str(err))
