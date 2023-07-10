FROM quay.io/pypa/manylinux2014_x86_64 as builder
LABEL maintainer="Shamil K (noteness@riseup.net)"

RUN yum -y install cmake wget openssl-devel

RUN mkdir /root/destdir

WORKDIR /root/cmake
ARG CMAKE_VERSION="3.26.4"
RUN wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz" && tar -xf "cmake-${CMAKE_VERSION}.tar.gz"
WORKDIR "/root/cmake/cmake-${CMAKE_VERSION}"
RUN cmake -DCMAKE_BUILD_TYPE=Release . && make -j "$(nproc)" && cmake --install . && cmake --install . --prefix /root/destdir

WORKDIR /root/ninja
ARG NINJA_VERSION="1.11.1"
RUN wget -q "https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz" && tar -xf "v${NINJA_VERSION}.tar.gz"
WORKDIR "/root/ninja/ninja-${NINJA_VERSION}"
RUN cmake -DCMAKE_BUILD_TYPE=Release -B build && cmake --build build -j"$(nproc)" && cmake --install build && cmake --install build --prefix /root/destdir

WORKDIR /root/llvm
ARG LLVM_VERSION="12.0.1"
RUN wget -q "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz" && tar -xf "llvm-${LLVM_VERSION}.src.tar.xz"
WORKDIR /root/llvm/llvm-${LLVM_VERSION}.src/build
RUN cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF  ../ && ninja && cmake --install . --prefix /root/destdir

WORKDIR /
FROM quay.io/pypa/manylinux2014_x86_64
COPY --from=builder /root/destdir /usr/local/

COPY entrypoint /usr/local/bin/entrypoint

ENTRYPOINT ["entrypoint"]
CMD ["/bin/bash"]
