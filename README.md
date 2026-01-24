docker run -d \
  --name debian-env \
  --restart always \
  -p 2222:22 \
  -e ssh_password=ssh密码 \
  -v /path:/root \
  -v /path:/usr/local/bin \
  ghcr.io/evecus/debian:latest
