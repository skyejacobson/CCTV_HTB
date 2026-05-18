#!/bin/bash

for port in 8765 8888 9081 8554 7999 1935 3306 33060; do
    echo "=== Port $port==="
    curl -sI --max-time 3 http://127.0.0.1:$port/ 2>&1 | head -5
    echo ""
done