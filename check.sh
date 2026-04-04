#!/bin/bash

python3 - <<EOF
from mcstatus import BedrockServer

server = BedrockServer.lookup("127.0.0.1:19132")

try:
    status = server.status()
    print("Server Online")
except Exception:
    print("Server Offline")
    exit()

try:
    print("Players:", status.players_online, "/", status.players_max)
except:
    pass

try:
    print("Latency:", status.latency, "ms")
except:
    pass
EOF
