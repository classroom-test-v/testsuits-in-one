#!/usr/bin/busybox sh

for item in date.lua file_io.lua max_min.lua random.lua remove.lua round_num.lua sin30.lua sort.lua strings.lua
do
	./lua ${item}
	if [ $? == 0 ]; then
		echo "testcase lua ${item} success"
	else
		echo "testcase lua ${item} fail"
	fi
done
