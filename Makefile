ARCH ?= riscv64

# CC := $(ARCH)-linux-musl-gcc
# CACHE_URL := musl.cc
# CACHE_URL := https://github.com/YdrMaster/zCore/releases/download/musl-cache
# TOOLCHAIN_TGZ := $(ARCH)-linux-musl-cross.tgz
CC := $(ARCH)-buildroot-linux-musl-gcc
CACHE_URL := https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs
TOOLCHAIN_TGZ := $(ARCH)--musl--bleeding-edge-2020.08-1.tar.bz2
TOOLCHAIN_URL := $(CACHE_URL)/$(TOOLCHAIN_TGZ)
export PATH=$(shell printenv PATH):$(CURDIR)/toolchain/$(ARCH)--musl--bleeding-edge-2020.08-1/bin

.PHONY: toolchian libc-test test clean

toolchain: 
	if [ ! -f toolchain/$(TOOLCHAIN_TGZ) ]; then wget -P toolchain $(TOOLCHAIN_URL); fi
	tar -xf toolchain/$(TOOLCHAIN_TGZ) -C toolchain

libc-test:
	git submodule update --init libc-test
	cd libc-test && make disk

image: libc-test
	sudo mkfs.fat -C -F 32 $(ARCH).img 100000
	rm -rf tmp && mkdir tmp
	sudo mount $(ARCH).img ./tmp
	
	# 将数据移入对应文件夹
	sudo cp -r libc-test/disk/* ./tmp

	sync && sudo umount ./tmp
	rmdir tmp
	
clean:
	rm -f $(ARCH).img

