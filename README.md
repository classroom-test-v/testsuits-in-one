作用
- 生成测试用的镜像

用法
```bash
make image ARCH=<arch> FS=<fs-type>	# 对于sfs,生成名为<fs-type>_<arch>.img的镜像。对于fat32, 生成<arch>.img,这是为了与之前的版本兼容。
	# <fs-type>目前只能是fat32或sfs。
	# <arch>目前可以是riscv64，x86_64, aarch64。
```

结果
- CI会把生成的镜像放在分支 `gh-pages`。

  
