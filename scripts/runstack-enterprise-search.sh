#!/bin/bash
docker-compose up -d

./wait-for-elasticsearch.sh

docker-compose --profile enterprise-search up -d

./update-kibana-user-password.sh

docker exec mongo1 /scripts/rs-init.sh
