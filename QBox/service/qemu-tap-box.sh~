#!bin/bash

##globals
PHY_INT=eth0
TAP_NAME=tap$$

start()
{
	 ovs-vsctl add-br qemu-br
	ovs-vsctl add-port qemu-br ${PHY_INT}
	ifconfig ${PHY_INT} 0
	ifconfig qemu-br ${ipNET}
	route add default gw ${gwWAN}	
	
	##ifconfig ${TAP_NAME} up

}

stop(){
	ovs-vsctl del-br qemu-br
	ovs-vsctl del-port ${TAP_NAME}
	ovs-vsct del-port ${PHY_INT}
	dhclient ${PHY_INT}
}

case $1 in 
	start|stop)
		"$1";;
	*)
		echo "usage:$0 {start|stop} "
		exit 1;;
esac
