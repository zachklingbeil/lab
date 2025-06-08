# [timefactory](https://timefactory.io)

## constants

[docker_engine](https://docs.docker.com/engine/install)
[nvidia_drivers](https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/index.html)
[nvidia_container_toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html)

# volumes

```docker network create --driver bridge timefactory
docker volume create caddy
docker volume create ethereum
docker volume create ollama
docker volume create postgres
docker volume create pgadmin
docker volume create registry
docker volume create redis
docker volume create insight
```

```
#backup, restore volumes
export
sudo tar -czvf <volume>.tar.gz -C /var/lib/docker/volumes <volume>

import
sudo tar -xzvf ~/volumes/registry.tar.gz -C /var/lib/docker/volumes

verify
docker volume ls
```
