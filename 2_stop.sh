# docker-compose
docker-compose -f mariadb_master.yml -p mariadb_master down
docker-compose -f mariadb_slave.yml -p mariadb_slave down

# network
docker network rm myNetwork
docker network ls

docker ps -a
