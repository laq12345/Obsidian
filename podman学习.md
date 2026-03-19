---
lang: Linux
date: 2026-03-19
tags:
  - 编程
---
podman换源：
```bash
sudo vim /etc/containers/registries.conf 
```

```
[[registry]]
location = "docker.io"
    [[registry.mirror]]
    location = "docker.m.daocloud.io"

[[registry]]
location = "gcr.io"
    [[registry.mirror]]
    location = "docker.m.daocloud.io"
```