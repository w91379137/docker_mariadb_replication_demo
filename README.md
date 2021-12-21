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
- ## 2 建立初始資料
第1台 master
```
docker exec -it mariadb_master bash
mysql -pCGV1YIBI4DG3H7KCSCFA

show databases;
use mydb;
```
建立會同步的表
```
create table if not exists test(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
show tables;

insert into test () VALUES (); #1
insert into test () VALUES (); #3
select * from test;
```
建立不同步的表
```
create table if not exists xtest(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
show tables;

insert into xtest () VALUES (); #1
insert into xtest () VALUES (); #3
select * from xtest;
```
第2台 slave
```
docker exec -it mariadb_slave bash
mysql -pCGV1YIBI4DG3H7KCSCFA

show databases;
use mydb;
```
建立會同步的表
```
create table if not exists test(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
show tables;

insert into test () VALUES (); #2
insert into test () VALUES (); #4
select * from test;
```
建立不同步的表
```
create table if not exists xtest(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
show tables;

insert into xtest () VALUES (); #2
insert into xtest () VALUES (); #4
select * from xtest;
```
- ## 3 匯出匯入資料
第1台 master 匯出
```
lock tables test read;
show open tables;
# 會看到 test 鎖定

exit # 離開 mysql
mysqldump -pCGV1YIBI4DG3H7KCSCFA mydb test > /var/log/mysql/test.sql

exit # 離開 docker
docker cp mariadb_master:/var/log/mysql/test.sql test.sql
docker cp test.sql mariadb_slave:/var/log/mysql/test.sql
```
第2台 slave 匯入
```
exit # 離開 mysql
mysql -pCGV1YIBI4DG3H7KCSCFA mydb < /var/log/mysql/test.sql

mysql -pCGV1YIBI4DG3H7KCSCFA
use mydb;
select * from test;
# 可以看到覆蓋後結果
```
- ## 4 查詢同步位置
查第1台
```
docker exec -it mariadb_master bash
mysql -pCGV1YIBI4DG3H7KCSCFA
show master status;
+-------------------+----------+--------------+------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-------------------+----------+--------------+------------------+
| master-log.000003 |     1664 | mydb         |                  |
+-------------------+----------+--------------+------------------+
```
查第2台
```
docker exec -it mariadb_slave bash
mysql -pCGV1YIBI4DG3H7KCSCFA
show master status;
+-------------------+----------+--------------+------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-------------------+----------+--------------+------------------+
| master-log.000003 |     2717 | mydb         |                  |
+-------------------+----------+--------------+------------------+
```


- ## 3 設定同步位置且同步
第1台
```
CHANGE MASTER TO MASTER_HOST='mariadb_slave', MASTER_USER='root', MASTER_PASSWORD='CGV1YIBI4DG3H7KCSCFA', MASTER_PORT=3306, MASTER_LOG_FILE='master-log.000003', MASTER_LOG_POS=2717;
start slave;
```
第2台
```
CHANGE MASTER TO MASTER_HOST='mariadb_master', MASTER_USER='root', MASTER_PASSWORD='CGV1YIBI4DG3H7KCSCFA', MASTER_PORT=3306, MASTER_LOG_FILE='master-log.000003', MASTER_LOG_POS=1664;
start slave;
```
- ## 4 檢查同步狀態

第12台
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
Last_IO_Error: # 這個必須是空的
```

- ## 5 [master]解除鎖定建立資料
```
use mydb;
unlock tables;
show open tables;
insert into test () VALUES (); #5
select * from test;
```

- ## 6 [slave]查詢同步資料

```
use mydb;
show tables;
select * from test;
# 可以看到 # 5

insert into test () VALUES (); #6
select * from test;
```

- ## 7 [master]查詢同步資料
```
use mydb;
show tables;
select * from test;
# 可以看到 # 6
```