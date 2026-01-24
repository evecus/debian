docker run -d \
  --name debian-env \
  --restart always \
  -p 2222:22 \
  -e ssh_password=ssh密码 \
  -v /path:/root \
  ghcr.io/evecus/debian-docker:latest
