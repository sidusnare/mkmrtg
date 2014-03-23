#!/bin/bash


for x in ethtool lsscsi vmstat iostat egrep awk uptime sed free indexmaker ;do
	if ! which $x >> /dev/null 2>> /dev/null;then
		echo -e "Missing Dependancy: $x\nPlease install $x and try again."
		exit 1
	fi
done

[ ! -d output ] && mkdir -v output
HOST=`hostname`
cat templates/base.cfg | sed -e "s/-=HOST=-/$HOST/g" > output/$HOST.cfg

for iface in `cat /proc/net/dev | awk -F : '{print($1)}' | egrep -v '^Inter-|^ face '`;do
	link=""
	link=`ethtool $iface 2>> /dev/null | grep '	Link detected: ' | sed -e 's/	Link detected: //'`
	if [ "$link" == "yes" ]; then
		cat templates/net.cfg | sed -e "s/-=HOST=-/$HOST/g" -e "s/-=IFACE=-/$iface/g" >> output/$HOST.cfg
	else
		echo "Skipping inactive interface: $iface"
	fi
done

for disk in `lsscsi | grep disk | sed -e 's#^.*/dev/##'`;do
	cat templates/disk.cfg | sed -e "s/-=HOST=-/$HOST/g" -e "s/-=DISK=-/$disk/g" >> output/$HOST.cfg
done

for cpu in `cat /proc/stat | grep ^cpu[0-9] | awk '{print($1)}'`;do
	cat templates/cpu.cfg | sed -e "s/-=HOST=-/$HOST/g" -e "s/-=CPU=-/$cpu/g" >> output/$HOST.cfg
done

indexmaker output/$HOST.cfg > output/index.$HOST.html

