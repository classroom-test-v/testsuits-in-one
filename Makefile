ARCH ?= riscv64

# CC := $(ARCH)-linux-musl-gcc
# CACHE_URL := musl.cc
# CACHE_URL := https://github.com/YdrMaster/zCore/releases/download/musl-cache
# TOOLCHAIN_TGZ := $(ARCH)-linux-musl-cross.tgz
CC := $(ARCH)-buildroot-linux-musl-gcc
OUTPUT_FOLDER=./build
CACHE_URL := https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs
TOOLCHAIN_TGZ := $(ARCH)--musl--bleeding-edge-2020.08-1.tar.bz2
TOOLCHAIN_URL := $(CACHE_URL)/$(TOOLCHAIN_TGZ)
LIBTIRPC := $(CURDIR)/libtirpc-1.3.3
export PATH=$(shell printenv PATH):$(CURDIR)/toolchain/$(ARCH)--musl--bleeding-edge-2020.08-1/bin

.PHONY: toolchian libc-test busybox lua lmbench libtirpc-1.3.3 test clean

toolchain: 
	if [ ! -f toolchain/$(TOOLCHAIN_TGZ) ]; then wget -P toolchain $(TOOLCHAIN_URL); fi
	tar -xf toolchain/$(TOOLCHAIN_TGZ) -C toolchain

busybox:
	cd busybox && make CROSS_COMPILE="$(ARCH)-buildroot-linux-musl-"
	cp busybox/busybox $(OUTPUT_FOLDER)
	cp scripts/busybox/* $(OUTPUT_FOLDER)

libc-test:
	cd libc-test && make disk
	cp -r libc-test/disk/* $(OUTPUT_FOLDER)

lua:
	cd lua && make posix CC="$(CC) -static"
	cp lua/src/lua $(OUTPUT_FOLDER)
	cp scripts/lua/* $(OUTPUT_FOLDER)

libtirpc-1.3.3:
	tar -jxvf libtirpc-1.3.3.tar.bz2
	cd libtirpc-1.3.3 && ./configure --host=riscv64-buildroot-linux-musl --prefix=/opt/riscv/sysroot/usr --disable-gssapi
	cd libtirpc-1.3.3 && make

lmbench: libtirpc-1.3.3
	cd lmbench && make build CC="riscv64-buildroot-linux-musl-gcc -static -I $(LIBTIRPC)/tirpc" -j$(nproc)
	cp lmbench/bin/x86_64-pc-linux-gnu/lmbench_all $(OUTPUT_FOLDER)
	cp scripts/lmbench/* $(OUTPUT_FOLDER)
	mkdir $(OUTPUT_FOLDER)/var/tmp -p

image: libc-test lua busybox lmbench
	@rm -f $(ARCH).img
	@dd if=/dev/zero of=$(ARCH).img count=81920 bs=512        # 40M
	@mkfs.vfat $(ARCH).img -F 32

	rm -rf tmp && mkdir tmp
	sudo mount $(ARCH).img ./tmp
	sudo cp -r $(OUTPUT_FOLDER)/* ./tmp
	sync && sudo umount ./tmp
	rmdir tmp
	
clean:
	rm -f $(ARCH).img
	rm -f OUTPUT_FOLDER/*
	cd libc-test && make clean
	cd lua && make clean
	cd busybox && make clean
	cd libtirpc-1.3.3 && make clean
	cd lmbench && make clean
