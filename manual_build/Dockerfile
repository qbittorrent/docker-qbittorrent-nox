# image for building
FROM alpine:latest AS builder

ARG QBT_VERSION
ARG LIBBT_VERSION="1.2.18"

# check environment variables
RUN \
  if [ -z "${QBT_VERSION}" ]; then \
    echo 'Missing QBT_VERSION variable. Check your command line arguments.' && \
    exit 1 ; \
  fi

# compiler, linker options:
# https://gcc.gnu.org/onlinedocs/gcc/Option-Summary.html
# https://gcc.gnu.org/onlinedocs/gcc/Link-Options.html
# https://sourceware.org/binutils/docs/ld/Options.html
ENV CFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS" \
    CXXFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS" \
    LDFLAGS="-gz -Wl,-O1,--as-needed,--sort-common,-z,now,-z,relro"

# alpine linux packages:
# https://git.alpinelinux.org/aports/tree/community/libtorrent-rasterbar/APKBUILD
# https://git.alpinelinux.org/aports/tree/community/qbittorrent/APKBUILD
RUN \
  apk --update-cache add \
    boost-dev \
    cmake \
    g++ \
    ninja \
    openssl-dev \
    patch \
    qt6-qtbase-dev \
    qt6-qttools-dev

# build libtorrent
RUN \
  wget -O libtorrent.tar.gz "https://github.com/arvidn/libtorrent/releases/download/v${LIBBT_VERSION}/libtorrent-rasterbar-${LIBBT_VERSION}.tar.gz" && \
  tar -xf libtorrent.tar.gz && \
  cd "libtorrent-rasterbar-${LIBBT_VERSION}" && \
  wget -O static_build.patch "https://github.com/arvidn/libtorrent/commit/a7be63c0f36371fcba020254c38f93710dd6df4b.patch" && \
  patch -Np1 -i static_build.patch && \
  cmake \
    -B build \
    -G Ninja \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -Ddeprecated-functions=OFF && \
  cmake --build build -j $(nproc) && \
  cmake --install build

# build qbittorrent
RUN \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    wget https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.zip && \
    unzip -q master.zip && \
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
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DGUI=OFF \
    -DQT6=ON && \
  cmake --build build -j $(nproc) && \
  cmake --install build

RUN \
  ldd /usr/bin/qbittorrent-nox

# image for running
FROM alpine:latest

RUN \
  apk --no-cache add \
    bash \
    curl \
    doas \
    musl-dbg \
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

COPY --from=builder /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
