ARCH ?= riscv64
FS ?= fat32

ifeq ($(FS),fat32)
	IMG_NAME := $(ARCH).img
else
	IMG_NAME := $(FS)_$(ARCH).img
endif
# CC := $(ARCH)-linux-musl-gcc
# CACHE_URL := musl.cc
# CACHE_URL := https://github.com/YdrMaster/zCore/releases/download/musl-cache
# TOOLCHAIN_TGZ := $(ARCH)-linux-musl-cross.tgz
CC := $(ARCH)-buildroot-linux-musl-gcc
OUTPUT_FOLDER=./build
ifeq ($(ARCH),x86_64)
	CACHE_URL := https://toolchains.bootlin.com/downloads/releases/toolchains/x86-64/tarballs
	TOOLCHAIN_NAME_ORG := x86-64--musl--bleeding-edge-2022.08-1
else
	CACHE_URL := https://toolchains.bootlin.com/downloads/releases/toolchains/$(ARCH)/tarballs
endif
ifeq ($(ARCH),riscv64)
	TOOLCHAIN_NAME_ORG := $(ARCH)--musl--bleeding-edge-2020.08-1
endif
ifeq ($(ARCH),aarch64)
	TOOLCHAIN_NAME_ORG := $(ARCH)--musl--bleeding-edge-2022.08-1
endif
TOOLCHAIN_TGZ := $(TOOLCHAIN_NAME_ORG).tar.bz2
TOOLCHAIN_URL := $(CACHE_URL)/$(TOOLCHAIN_TGZ)
TOOLCHAIN_NAME_TGT := $(ARCH)--musl--bleeding-edge
LIBTIRPC := $(CURDIR)/libtirpc-1.3.3
export PATH=$(shell printenv PATH):$(CURDIR)/toolchain/$(TOOLCHAIN_NAME_TGT)/bin

.PHONY: toolchain libc-test busybox lua lmbench libtirpc-1.3.3 test clean

toolchain: 
	if [ ! -f toolchain/$(TOOLCHAIN_TGZ) ]; then wget -P toolchain $(TOOLCHAIN_URL); fi
	tar -xf toolchain/$(TOOLCHAIN_TGZ) -C toolchain
	cd toolchain && mv $(TOOLCHAIN_NAME_ORG) $(TOOLCHAIN_NAME_TGT)

busybox:
	cd busybox && make CROSS_COMPILE="$(ARCH)-buildroot-linux-musl-"
	if [ ! -d $(OUTPUT_FOLDER) ]; then mkdir $(OUTPUT_FOLDER); fi
	cp busybox/busybox $(OUTPUT_FOLDER)
	cp scripts/busybox/* $(OUTPUT_FOLDER)

libc-test:
	cd libc-test && make disk ARCH=$(ARCH)
	if [ ! -d $(OUTPUT_FOLDER) ]; then mkdir $(OUTPUT_FOLDER); fi
	cp -r libc-test/disk/* $(OUTPUT_FOLDER)

lua:
	cd lua && make posix CC="$(CC) -static"
	if [ ! -d $(OUTPUT_FOLDER) ]; then mkdir $(OUTPUT_FOLDER); fi
	cp lua/src/lua $(OUTPUT_FOLDER)
	cp scripts/lua/* $(OUTPUT_FOLDER)

libtirpc-1.3.3:
	tar -jxvf libtirpc-1.3.3.tar.bz2
	cd libtirpc-1.3.3 && ./configure --host=$(ARCH)-buildroot-linux-musl --prefix=/opt/riscv/sysroot/usr --disable-gssapi
	cd libtirpc-1.3.3 && make

lmbench: libtirpc-1.3.3
	cd lmbench && make build LIBTIRPC="$(LIBTIRPC)/src/.libs" CC="$(CC) -static -I $(LIBTIRPC)/tirpc" -j$(nproc)
	cp lmbench/bin/x86_64-pc-linux-gnu/lmbench_all $(OUTPUT_FOLDER)
	cp scripts/lmbench/* $(OUTPUT_FOLDER)
	mkdir $(OUTPUT_FOLDER)/var/tmp -p

image: libc-test lua busybox lmbench
	mkdir -p $(OUTPUT_FOLDER)/bin $(OUTPUT_FOLDER)/lib
	cp $(OUTPUT_FOLDER)/busybox $(OUTPUT_FOLDER)/bin
	cd $(OUTPUT_FOLDER)/bin/ && ln -f busybox echo
	cd $(OUTPUT_FOLDER)/bin/ && ln -f busybox ls
	cp $(OUTPUT_FOLDER)/*so $(OUTPUT_FOLDER)/lib
ifeq ($(FS),fat32)
	@rm -f $(IMG_NAME)
	@dd if=/dev/zero of=$(IMG_NAME) count=81920 bs=512        # 40M
	@/sbin/mkfs.vfat $(IMG_NAME) -F 32

	rm -rf tmp && mkdir tmp
	sudo mount $(IMG_NAME) ./tmp
	sudo cp -r $(OUTPUT_FOLDER)/* ./tmp
	sync && sudo umount ./tmp
	rmdir tmp
endif
ifeq ($(FS),sfs)
	rcore-fs-fuse $(IMG_NAME) $(OUTPUT_FOLDER) zip
	qemu-img resize -f raw $(IMG_NAME) +5M
endif
	
clean:
	rm -f $(IMG_NAME)
	rm -rf $(OUTPUT_FOLDER)
	cd libc-test && make clean
	cd lua && make clean
	cd busybox && make clean
	cd libtirpc-1.3.3 && make clean
	cd lmbench && make clean
