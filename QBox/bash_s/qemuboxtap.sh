#!/bin/bash

# Copyright (C) 2016 Nafiu Shaibu.

HD_IMG_DIR=$HOME/.img_qemubox ##contains harddisk images
BOOT_DIR=${HD_IMG_DIR}/.qemuboot ## contain boot files


printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

TAP_NAME="tap`expr $RANDOM % 20`"
PHY_INT="eth0"
HD_IMG_DIR=$HOME/.img_qemubox
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
LOG_DIR=${HD_IMG_DIR}/logs_dir

find ${BOOT_DIR} -depth -type f -a -name $1 -exec cat {} \; 1> ${TEMP_FOLDER}/.tapbootconf.tt 2>/dev/null

sudo chmod 666 /dev/net/tun

TAP_NAME=`sudo tunctl -u `whoami` -t ${TAP_NAME} 2>/dev/null`

##create a virtual bridge or switch
sudo brctl addbr br0
sudo ifconfig br0 up
sudo ip addr flush dev ${PHY_INT} 2>/dev/null
sudo ip addr flush dev ${TAP_NAME} 2>/dev/null

sudo brctl stp br0 off 2>/dev/null
sudo brctl setfd br0 1 2>/dev/null
sudo brctl sethello br0 1 2>/dev/null

##adding interfaces to virtual bridge
sudo brctl addif br0 ${PHY_INT} 2>/dev/null
sudo brctl addif br0 ${TAP_NAME} 2>/dev/null
sudo ifconfig ${TAP_NAME} up

echo "$(cat ${TEMP_FOLDER}/.tapbootconf.tt) -net nic,macaddr=${MACADDR},vlan=0 -net tap,ifname=${TAP_NAME},vlan=0,script=no" >${TEMP_FOLDER}/.boottap_tmp.qvm

rm -f ${TEMP_FOLDER}/.tapbootconf.tt
BOOTTMP=`find ${TEMP_FOLDER} -type f -a -name ".boottap_tmp.qvm" -exec cat {} \; 2>/dev/null`

${BOOTTMP} & 


exit 0
