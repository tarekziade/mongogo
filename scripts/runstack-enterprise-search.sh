#!/bin/bash
docker-compose up -d

./wait-for-elasticsearch.sh

docker-compose --profile enterprise-search up -d

./wait-for-kibana.sh
./update-kibana-user-password.sh

./wait-for-mongo.sh

docker exec mongo1 /scripts/rs-init.sh
