#!/bin/bash

ACTION=$1

case $ACTION in
  "start")
    docker compose up -d
    ;;
  "stop")
    docker compose down
    ;;
  "restart")
    docker compose restart
    ;;
  "logs")
    docker compose logs -f
    ;;
  "status")
    docker compose ps
    ;;
  "update")
    docker compose pull
    docker compose up -d --force-recreate
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|logs|status|update}"
    ;;
esac