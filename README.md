# docker_mariadb_replication_demo

目標

使用 docker 搭建兩個 mariadb 達到部分 table 同步

1 建立兩個資料庫
docker-compose -f 1_mariadb_master.yml -p 1_mariadb_master up -d

docker-compose -f 2_mariadb_slave.yml -p 2_mariadb_slave up -d