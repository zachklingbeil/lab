Flatten deployment of blockscout with all microservices. Bring an existing postgres, redis db. Connect services via docker bridge network, expose through caddy.

http://frontend:3000
http://backend:4000

http://stats:8050
http://visualizer:8050
http://sig-provider:8050/
http://sc-verifier:8050/
http://user-ops-indexer:8050/

ACCOUNT_REDIS_URL=redis://redis:6379
DATABASE_URL=
STATS_DATABASE_URL=
