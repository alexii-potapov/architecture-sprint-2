#!/bin/bash

###
# Настройка сервера конфигураций
###

docker compose exec -T configSrv mongosh --port 27019 <<EOF
 rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27019" }
    ]
  });
EOF


###
# Настройка shard1
###
docker compose exec -T shard1_1 mongosh --port 27018 <<EOF
rs.initiate(
  {
    _id: "shard1",
    members: [
      { _id : 0, host : "shard1_1:27018" },
      { _id : 1, host : "shard1_2:27018" },	  
      { _id : 2, host : "shard1_3:27018" }
    ]
  }
);
EOF


###
# Настройка shard2
###

docker compose exec -T shard2_1 mongosh --port 27018 <<EOF
rs.initiate(
  {
    _id: "shard2",
    members: [
      { _id : 0, host : "shard2_1:27018" },
      { _id : 1, host : "shard2_2:27018" },	  
      { _id : 2, host : "shard2_3:27018" }
    ]
  }
);
EOF


###
# Настройка шардирования БД и наполнение начальными данными
###

docker exec -it mongos_router_1 mongosh --port 27017 <<EOF
 
sh.addShard( "shard1/shard1_1:27018,shard1_2:27018,shard1_3:27018");
sh.addShard( "shard2/shard2_1:27018,shard2_2:27018,shard2_3:27018");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
EOF


###
# Инициализируем бд
###

docker exec -it mongos_router_1 mongosh --port 27017 <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF


