作用
- 生成测试用的镜像

用法
```bash
make image ARCH=<arch> FS=<fs-type>	# 生成名为<fs-type>_<arch>.img的镜像。
	# <fs-type>目前只能是fat32或sfs。
	# <arch>目前只能是riscv64。
```

结果
- CI会把生成的镜像放在分支 `gh-pages`。

  