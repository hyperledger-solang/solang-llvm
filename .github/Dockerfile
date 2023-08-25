FROM ubuntu:20.04 as builder

LABEL org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.description="CI container for Hyperledger Solang github actions"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y libz-dev pkg-config libssl-dev git cmake ninja-build gcc g++ python3 file

RUN git clone --single-branch --branch solana-rustc/15.0-2022-08-09 \
    https://github.com/solana-labs/llvm-project.git

WORKDIR /llvm-project

RUN cmake -G Ninja -DLLVM_ENABLE_ASSERTIONS=On -DLLVM_ENABLE_TERMINFO=Off \
    -DLLVM_ENABLE_PROJECTS=clang\;lld \
    -DLLVM_TARGETS_TO_BUILD=WebAssembly\;SBF \
    -DLLVM_ENABLE_ZSTD=Off \
    -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=/llvm15.0 llvm

RUN cmake --build . --target install && \
	find /llvm15.0/ -type f -executable -exec sh -c "file '{}' | grep -q 'not stripped' " \; -print | xargs strip

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
	apt-get install -y zlib1g-dev pkg-config libssl-dev git libffi-dev curl gcc g++ make python3 file && \
	apt-get clean && \
	apt-get autoclean

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --default-toolchain 1.70.0 --profile minimal

COPY --from=builder /llvm15.0 /llvm15.0/

ENV PATH="/llvm15.0/bin:/root/.cargo/bin:/root/.local/share/solana/install/active_release/bin:${PATH}"

# Install Solana (x86-64 only, does not work on arm)
RUN if test `arch` = x86_64; then \
		sh -c "$(curl -sSfL https://release.solana.com/v1.16.1/install)" && \
		find /root/.local/share/solana/install/releases/1.16.1/solana-release/bin/ -type f -executable -exec sh -c "file '{}' | grep -q 'not stripped' " \; -print | xargs strip; \
		rm /root/.local/share/solana/install/active_release/bin/solang; \
	fi && \
	cargo install --git https://github.com/coral-xyz/anchor --tag v0.28.0 anchor-cli && \
	rm -rf /root/.cargo/registry
