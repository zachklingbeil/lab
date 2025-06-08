# registry

```
from compose/registry
mkdir auth

docker run --rm --entrypoint htpasswd httpd:2 -Bbn <username> <password> > auth/htpasswd*
docker run --rm --entrypoint htpasswd httpd:2 -Bbn zk <password> > auth/htpasswd*

echo "<password>" | docker login https://docker.zachklingbeil.com --username zk --password-stdin

docker build -t docker.zachklingbeil.com/<image>:<tag> . --push
docker pull docker.zachklingbeil.com/<image>:<tag>

```
