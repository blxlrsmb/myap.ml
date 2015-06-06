#!/bin/bash
if [[ $1 == 'post' ]]; then
  curl -v http://25.0.0.214:8080/client/$2 -X POST -H "Content-Type: application/json" -d '{"timestamp":23}'
elif [[ $1 == 'get' ]]; then
  curl -v http://localhost:8080/client/$2 -X GET
fi
