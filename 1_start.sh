# network
docker network create myNetwork
docker network ls

# docker-compose
docker-compose -f mariadb_master.yml -p mariadb_master up -d
docker-compose -f mariadb_slave.yml -p mariadb_slave up -d

docker ps -a
