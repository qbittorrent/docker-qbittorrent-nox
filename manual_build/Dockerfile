# image for building
FROM alpine:latest AS builder

ARG QBT_VERSION

# Check environment variables
RUN \
  if [ -z "$QBT_VERSION" ]; then \
    echo 'Missing $QBT_VERSION variable. Check your command line arguments.' && \
    exit 1 ; \
  fi

# Compiler, linker options:
# https://gcc.gnu.org/onlinedocs/gcc/Option-Summary.html
# https://gcc.gnu.org/onlinedocs/gcc/Link-Options.html
# https://sourceware.org/binutils/docs/ld/Options.html
ENV CFLAGS="-pipe -fcf-protection -fstack-clash-protection -fstack-protector-strong -fno-plt -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS" \
    CXXFLAGS="-pipe -fcf-protection -fstack-clash-protection -fstack-protector-strong -fno-plt -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS" \
    LDFLAGS="-gz -Wl,-O1,--as-needed,--sort-common,-z,now,-z,relro"

# alpine linux packages:
# https://git.alpinelinux.org/aports/tree/community/libtorrent-rasterbar/APKBUILD
# https://git.alpinelinux.org/aports/tree/community/qbittorrent/APKBUILD
RUN \
  apk --update-cache add \
    boost-dev \
    cmake \
    g++ \
    libtorrent-rasterbar-dev \
    ninja \
    qt6-qtbase-dev \
    qt6-qttools-dev

RUN \
  if [ "$QBT_VERSION" = "devel" ]; then \
    wget https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.zip && \
    unzip master.zip && \
    cd qBittorrent-master ; \
  else \
    wget "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz" && \
    tar -xf "release-${QBT_VERSION}.tar.gz" && \
    cd "qBittorrent-release-${QBT_VERSION}" ; \
  fi && \
  cmake \
    -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DGUI=OFF \
    -DQT6=ON && \
  cmake --build build -j $(nproc) && \
  cmake --install build

# image for running
FROM alpine:latest

RUN \
  apk --no-cache add \
    bash \
    curl \
    doas \
    libtorrent-rasterbar \
    python3 \
    qt6-qtbase \
    tini \
    tzdata

RUN \
  adduser \
    -D \
    -H \
    -s /sbin/nologin \
    -u 1000 \
    qbtUser && \
  echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

COPY --from=builder /usr/local/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
