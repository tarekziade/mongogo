curl -u elastic:changeme http://localhost:9200/ingest-connectors -X DELETE
curl -u elastic:changeme http://localhost:9200/ingest-config -X DELETE
curl -u elastic:changeme http://localhost:9200/search-airbnb -X DELETE
curl -X DELETE -u elastic:changeme http://localhost:3002/api/as/v1/engines/as-search-airbnb
