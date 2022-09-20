ARCH ?= riscv64
FS ?= fat32

IMG_NAME := $(FS)_$(ARCH).img
# CC := $(ARCH)-linux-musl-gcc
# CACHE_URL := musl.cc
# CACHE_URL := https://github.com/YdrMaster/zCore/releases/download/musl-cache
# TOOLCHAIN_TGZ := $(ARCH)-linux-musl-cross.tgz
CC := $(ARCH)-buildroot-linux-musl-gcc
OUTPUT_FOLDER=./build
CACHE_URL := https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs
TOOLCHAIN_TGZ := $(ARCH)--musl--bleeding-edge-2020.08-1.tar.bz2
TOOLCHAIN_URL := $(CACHE_URL)/$(TOOLCHAIN_TGZ)
export PATH=$(shell printenv PATH):$(CURDIR)/toolchain/$(ARCH)--musl--bleeding-edge-2020.08-1/bin

.PHONY: toolchian libc-test busybox lua test clean

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

image: libc-test lua busybox
ifeq ($(FS),fat32)
	mkdir $(OUTPUT_FOLDER)/bin $(OUTPUT_FOLDER)/lib
	cp $(OUTPUT_FOLDER)/busybox $(OUTPUT_FOLDER)/bin
	cp $(OUTPUT_FOLDER)/*so $(OUTPUT_FOLDER)/lib
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

