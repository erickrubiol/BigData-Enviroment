
# Conectarse a maquina virtual en Azure
sudo ssh -i /mnt/c/Users/erick/Desktop/app/dwh-unir_key.pem erick@40.121.63.151

# COnfiguracion de maquina virtual
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io
sudo apt  install docker-compose -y
sudo service docker status

# Para consultar aplicaciones con salida HTML
http://dwh-unir.eastus.cloudapp.azure.com:32768/
http://dwh-unir.eastus.cloudapp.azure.com:8080 # Spark
http://dwh-unir.eastus.cloudapp.azure.com:6980/nifi/ # NiFi
http://dwh-unir.eastus.cloudapp.azure.com:9870/dfshealth.html#tab-overview # HDFS

# Copiar archivos a la VM
sudo scp -i /mnt/c/Users/erick/Desktop/app/dwh-unir_key.pem /mnt/c/Users/erick/Desktop/app/docker-compose.yml erick@40.121.63.151:/home/erick/docker-compose.yml
sudo scp -i /mnt/c/Users/erick/Desktop/app/dwh-unir_key.pem /home/erick/example.parquet erick@40.121.63.151:/home/erick/example.parquet

## Configuracion de contenedores
docker volume create --name=data
docker network create -d bridge hadoopspark
docker network create -d bridge dwh-network


## Start enviroment
docker network create -d bridge hadoopspark
docker run --name spark-master --hostname sparkmaster --network=hadoopspark -v "D:/PROJECTS/hadoopspark:/opt/hadoopspark" -p 8090:8080 -p 7077:7077 -d bde2020/spark-master:3.0.1-hadoop3.2
docker run --name spark-worker-1 --network=hadoopspark -p 8081:8081 -e "SPARK_MASTER=sparkmaster:7077" -d bde2020/spark-worker:3.0.1-hadoop3.2
docker run --name spark-worker-2 --network=hadoopspark -p 8082:8081 -e "SPARK_MASTER=sparkmaster:7077" -d bde2020/spark-worker:3.0.1-hadoop3.2
docker run --name namenode --network=hadoopspark -v "D:/PROJECTS/hadoopspark:/opt/hadoopspark" -e "CORE_CONF_fs_defaultFS=hdfs://namenode:9000" -e "CLUSTER_NAME=hadooptest" -p 9870:9870 -p 9000:9000 -d bde2020/hadoop-namenode
docker run --name datanode --network=hadoopspark -e "CORE_CONF_fs_defaultFS=hdfs://namenode:9000" -d bde2020/hadoop-datanode


## HDFS
docker cp /home/erick/example.parquet namenode:/example.parquet
docker exec -it namenode bash
hdfs dfs -mkdir /airlines
hdfs dfs -put example.parquet /airlines
hadoop fs -chmod -R 777 /airlines # Dar permisos a NiFi
cp /etc/hadoop/core-site.xml /opt/hadoopspark # Copiar configuracion de Hdfs a NiFi
cp /etc/hadoop/hdfs-site.xml /opt/hadoopspark

## Spark
docker exec -it spark-master bash
/spark/bin/spark-shell --master spark://spark-master:7077
import spark.implicits._
val parquetFile = spark.read.parquet("hdfs://namenode:9000/airlines/*")
parquetFile.show()

## NiFi



Procesador InvokeHTTP
RemoteURL:	http://api.open-notify.org/iss-now.json

Procesador PutHDFS
Hadoop Configuration Resources: /opt/hadoopspark/core-site.xml,/opt/hadoopspark/hdfs-site.xml
/airlines/${now():format("yyyy-MM-dd")}


## URLS
http://localhost:9870/explorer.html#/ #HDFS




## Utilidades docker

# Detener todos los contenedores
docker stop $(docker ps -a -q)

# Eliminar todos los contenedores
docker rm $(docker ps -a -q)