#!/bin/bash
curl http://localhost:8080/hello/23 -X POST -H "Content-Type: application/json" -d '{"a": 34}'

