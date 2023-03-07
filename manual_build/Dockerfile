# image for building
FROM alpine:latest AS builder

ARG QBT_VERSION
ARG LIBBT_CMAKE_FLAGS=""
ARG LIBBT_VERSION="1.2.18"

# check environment variables
RUN \
  if [ -z "${QBT_VERSION}" ]; then \
    echo 'Missing QBT_VERSION variable. Check your command line arguments.' && \
    exit 1 ; \
  fi

# alpine linux packages:
# https://git.alpinelinux.org/aports/tree/community/libtorrent-rasterbar/APKBUILD
# https://git.alpinelinux.org/aports/tree/community/qbittorrent/APKBUILD
RUN \
  apk --update-cache add \
    boost-dev \
    cmake \
    git \
    g++ \
    ninja \
    openssl-dev \
    patch \
    qt6-qtbase-dev \
    qt6-qttools-dev

# compiler, linker options:
# https://gcc.gnu.org/onlinedocs/gcc/Option-Summary.html
# https://gcc.gnu.org/onlinedocs/gcc/Link-Options.html
# https://sourceware.org/binutils/docs/ld/Options.html
ENV CFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS" \
    CXXFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS" \
    LDFLAGS="-gz -Wl,-O1,--as-needed,--sort-common,-z,now,-z,relro"

# build libtorrent
RUN \
  if [ "${LIBBT_VERSION}" = "devel" ]; then \
    git clone \
      --depth 1 \
      --recurse-submodules \
      https://github.com/arvidn/libtorrent.git && \
    cd libtorrent ; \
  else \
    wget "https://github.com/arvidn/libtorrent/releases/download/v${LIBBT_VERSION}/libtorrent-rasterbar-${LIBBT_VERSION}.tar.gz" && \
    tar -xf "libtorrent-rasterbar-${LIBBT_VERSION}.tar.gz" && \
    cd "libtorrent-rasterbar-${LIBBT_VERSION}" ; \
  fi && \
  wget -O static_build.patch "https://github.com/arvidn/libtorrent/commit/a7be63c0f36371fcba020254c38f93710dd6df4b.patch" && \
  patch -Np1 -i static_build.patch || true && \
  cmake \
    -B build \
    -G Ninja \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -Ddeprecated-functions=OFF \
    $LIBBT_CMAKE_FLAGS && \
  cmake --build build -j $(nproc) && \
  cmake --install build

# build qbittorrent
RUN \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    git clone \
      --depth 1 \
      --recurse-submodules \
      https://github.com/qbittorrent/qBittorrent.git && \
    cd qBittorrent ; \
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
  ldd /usr/bin/qbittorrent-nox | sort -f

# record compile-time Software Bill of Materials (sbom)
RUN \
  printf "Software Bill of Materials for building qbittorrent-nox\n\n" >> /sbom.txt && \
  if [ "${LIBBT_VERSION}" = "devel" ]; then \
    cd libtorrent && \
    echo "libtorrent-rasterbar git $(git rev-parse HEAD)" >> /sbom.txt && \
    cd .. ; \
  else \
    echo "libtorrent-rasterbar ${LIBBT_VERSION}" >> /sbom.txt ; \
  fi && \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    cd qBittorrent && \
    echo "qBittorrent git $(git rev-parse HEAD)" >> /sbom.txt && \
    cd .. ; \
  else \
    echo "qBittorrent ${QBT_VERSION}" >> /sbom.txt ; \
  fi && \
  echo >> /sbom.txt && \
  apk list -I | sort >> /sbom.txt && \
  cat /sbom.txt

# image for running
FROM alpine:latest

RUN \
  apk --no-cache add \
    bash \
    curl \
    doas \
    python3 \
    qt6-qtbase \
    qt6-qtbase-sqlite \
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

COPY --from=builder /sbom.txt /sbom.txt

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
