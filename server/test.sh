#!/bin/bash
curl -v http://localhost:8080/client/$1 -X POST -H "Content-Type: application/json" -d '{"a": 34}'
# curl -v http://localhost:8080/client/$1 -X GET
