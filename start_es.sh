#!/bin/bash

# This will start a docker container that will run both ElasticSearch and kibana
# ElasticSearch can be reached on port 9200
# Kibana front-end can be reached at http://localhost:5601/app/kibana

# to kill, once started, run `docker kill elasticsearch-local`

docker run -d -p 9200:9200 -p 5601:5601 --name elasticsearch-local nshou/elasticsearch-kibana
