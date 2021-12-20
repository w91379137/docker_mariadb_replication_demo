# docker_mariadb_replication_demo

## 目標

使用 docker 搭建兩個 mariadb 達到部分 table 同步

- ## 1 建立兩個資料庫

### 啟動 container
```
./1_start.sh
```

### 關閉 container
```
./2_stop.sh
```

- ## 2 [master]查詢同步位置

```
docker exec -it mariadb_master bash
mysql -pCGV1YIBI4DG3H7KCSCFA
show master status;

+-------------------+----------+--------------+------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-------------------+----------+--------------+------------------+
| master-log.000003 |      343 | mydb         |                  |
+-------------------+----------+--------------+------------------+
```

- ## 3 [slave]設定同步位置且同步

```
docker exec -it mariadb_slave bash
mysql -pCGV1YIBI4DG3H7KCSCFA

CHANGE MASTER TO MASTER_HOST='mariadb_master', MASTER_USER='root', MASTER_PASSWORD='CGV1YIBI4DG3H7KCSCFA', MASTER_PORT=3306, MASTER_LOG_FILE='master-log.000003', MASTER_LOG_POS=343;
start slave;
```

- ## 4 [slave]檢查同步狀態

```
show slave status\G;
```

注意其中的
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
...
Replicate_Do_DB: mydb
...
Replicate_Wild_Do_Table: mydb.test%
...
Exec_Master_Log_Pos: 343
...
Last_IO_Errno: 0
Last_IO_Error:
```

- ## 5 [master]建立資料

建立會同步的表
```
show databases;
use mydb;
create table if not exists test(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
show tables;
insert into test () VALUES ();
select * from test;
```
建立不同步的表
```
use mydb;
create table if not exists xtest(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
show tables;
insert into xtest () VALUES ();
select * from xtest;
```

- ## 6 [slave]查詢同步資料

```
use mydb;
show tables;
select * from test;
```