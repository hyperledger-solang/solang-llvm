#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR=./llvm16.0/
mkdir -p $INSTALL_DIR


cd llvm-project
patch -p1 < ../patches/llvm-D70401.patch
patch -p1 < ../patches/compiler-rt.patch


mkdir -p build
cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DLLVM_ENABLE_PROJECTS='clang;lld' -DLLVM_TARGETS_TO_BUILD="X86;AArch64;RISCV;WebAssembly" -DLLVM_ENABLE_RUNTIMES=compiler-rt ../llvm
ninja
ninja install


cd ../compiler-rt
mkdir -p build
cd build

CFLAGS="--target=riscv32 -march=rv32em -mabi=ilp32e -nostdlib -nodefaultlibs -flto -save-temps"
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
    -DCOMPILER_RT_BAREMETAL_BUILD=ON \
    -DCMAKE_AR=$INSTALL_DIR/bin/llvm-ar \
    -DCMAKE_ASM_COMPILER_TARGET="riscv32" \
    -DCMAKE_ASM_FLAGS="$CFLAGS" \
    -DCMAKE_C_COMPILER=$INSTALL_DIR/bin/clang \
    -DCMAKE_C_COMPILER_TARGET="riscv32" \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
    -DCMAKE_NM=$INSTALL_DIR/bin/llvm-nm \
    -DCMAKE_RANLIB=$INSTALL_DIR/bin/llvm-ranlib \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DLLVM_CONFIG_PATH=$INSTALL_DIR/bin/llvm-config \
    ..
ninja
ninja install


echo ""
echo "success"

