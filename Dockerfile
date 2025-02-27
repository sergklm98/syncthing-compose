FROM alpine:latest AS base
ARG SYNCTHING_VERSION=latest
ARG RELAYSRV_VERSION=latest
ARG DISCOSRV_VERSION=latest
RUN <<EOF
cat <<'EOS' >/bin/download_and_install
#!/bin/sh
repo=$1 # syncthing/syncthing
binary=$2 # syncthing
version=${3:-latest} # latest
arch=${4:-amd64} # amd64
cd /tmp
if [[ "$version" == "latest" ]]; then
  apk add jq
  wget https://api.github.com/repos/$repo/releases/latest
  version=$(jq -r .tag_name latest)
  apk del jq
  echo $version
fi
wget https://github.com/$repo/releases/download/$version/$binary-linux-$arch-$version.tar.gz
tar -xzf $binary-linux-$arch-$version.tar.gz $binary-linux-$arch-$version/$binary
install $binary-linux-$arch-$version/$binary /usr/local/bin/$binary
rm -rf ./*
cd -
$binary --version
EOS
chmod +x /bin/download_and_install
EOF

FROM base AS syncthing
ARG SYNCTHING_VERSION
RUN download_and_install syncthing/syncthing syncthing $SYNCTHING_VERSION
EXPOSE 8384 22000/tcp 22000/udp  21027/udp
CMD ["/usr/local/bin/syncthing"]

FROM base AS strelaysrv
ARG RELAYSRV_VERSION
RUN download_and_install syncthing/relaysrv strelaysrv $RELAYSRV_VERSION
WORKDIR /relay
EXPOSE 22067 22070
CMD ["/usr/local/bin/strelaysrv"]

FROM base AS stdiscosrv
ARG DISCOSRV_VERSION
RUN download_and_install syncthing/discosrv stdiscosrv $DISCOSRV_VERSION
WORKDIR /discovery
CMD ["/usr/local/bin/stdiscosrv"]
