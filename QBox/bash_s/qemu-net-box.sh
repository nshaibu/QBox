#!/bin/bash

# Copyright (C) 2016 Nafiu Shaibu.
#
#
# Qemu-net-box is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your option) 
# any later version.

# Qemu-net-box is distributed in the hopes that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##globals
PHY_INT_ETH="eth0"
NIC_MODEL=""
HD_IMG_DIR=$HOME/.img_qemubox
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
LOG_DIR=${HD_IMG_DIR}/logs_dir
HOST_IP=""
GUEST_IP=""

QBOX_DIR=/usr/local/bin/QBox

TAP_NAME="tap`${QBOX_DIR}/bin/qemubox_random 10`"

printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

function yes_no(){
	read resp
	case "$resp" in 
		[Yy]|[Yy][Ee][Ss]) echo 0;;
		*) echo 1 ;;
	esac
}


function nic_model()
{
	echo "   ->The system can emulate this nic models."
	echo "   ->[e1000[DEFAULT],virtio,i82551,i82557b,i82559er,ne2k_isa,pcnet,rtl8139,lance,mcf_fec]"
	read nicc
	
	case "$nicc" in 
		[Vv][Ii][Rr][Tt][Ii][Oo]) NIC_MODEL="virtio";;
		[Ii]82551) NIC_MODEL="i82551";;
		[Ii]82557[Bb]) NIC_MODEL="i82557b";;
		[Ii]8255[Ee][Rr]) NIC_MODEL="i82559er";;
		[Nn][Ee]2[Kk]_[Ii][Ss][Aa]) NIC_MODEL="ne2k_isa";;
		[Rr][Tt][Ll]8139) NIC_MODEL="rtl8139";;
		[Ll][Aa][Nn][Cc]) NIC_MODEL="lance";;
		[Mm][Cc][Ff]_[Ff][Ee][Cc]) NIC_MODEL="mcf_fec";;
		*) NIC_MODEL="e1000";;
	esac
	
	return 0
}

##logger_func sed ':a;N;$!ba;s/\n/ /g'
#1. :a create a label 'a'
#2. N append the next line to the pattern space
#3. $! if not the last line, ba branch (go to) label 'a'
#4. s substitute, /\n/ regex for new line, / / by a space, /g global match (as many times as it can)
function logger_logging(){
	if [ "`cat ${TEMP_FOLDER}/.error.tt`" != "" ]; then 
		${QBOX_DIR}/bin/qemubox_logger "`sed ':a;N;$!ba;s/\n/ /g' ${TEMP_FOLDER}/.error.tt`" ${LOG_DIR}/qboxlog
	
		rm -f ${TEMP_FOLDER}/.error.tt
	fi
	return 0
}

tap_if_creation_bridging()
{
	##linux kernels has built-in bridge or switch and this can be access with the brctl
	##command. The virtual switch enable the addition and bridging of virtual interfaces or ports
	##with physical interfaces.
	
	sudo chmod 666 /dev/net/tun
	TAP_NAME=`sudo tunctl -u `whoami` -t ${TAP_NAME} 2>${TEMP_FOLDER}/.error.tt`
	logger_logging
	
	sudo brctl addbr br0
	sudo ip addr flush dev ${PHY_INT_ETH} 2>${TEMP_FOLDER}/.error.tt
	logger_logging
	
	sudo ip addr flush dev ${TAP_NAME} 2>${TEMP_FOLDER}/.error.tt
	logger_logging
	
	sudo brctl stp br0 off 2>${TEMP_FOLDER}/.error.tt
	logger_logging
	
	sudo brctl setfd br0 1 2>${TEMP_FOLDER}/.error.tt
	logger_logging
	
	sudo brctl sethello br0 1 2>${TEMP_FOLDER}/.error.tt
	logger_logging
	
	sudo brctl addif br0 ${PHY_INT_ETH} 2>${TEMP_FOLDER}/.error.tt
	logger_logging
	
	sudo brctl addif br0 ${TAP_NAME}  2>${TEMP_FOLDER}/.error.tt
	logger_logging
}

SOCKET1= 
VLAN_SOCKET1= 
FD_SOCKET1= 
LISTEN1= 
CONNECT1= 
MCAST1= 
#SMB_SERVER
# REDIRECT
echo && printf "%s\n" "Configure networking for your VM"
printf "%s\n" "   ->Option:[user[DEFAULT] --> User_Networking]" \
		      "            [tap           --> Bridging]"
read ntwk

case "$ntwk" in 
	[Tt][Aa][Pp]|[Tt])
		tap_if_creation_bridging
		nic_model
		
		TAP1="-net tap" 
		VLAN_TAP1=",vlan=0" 
		FD_TAP1= 
		IFNAME1=",ifname=${TAP_NAME}" 
		SCRIPT1=",script=no" 
		MODEL1=",model=${NIC_MODEL}"
		echo 1>${TEMP_FOLDER}/.test_tap_exit.tt ## if this file exist then the vm is configured to use tap
		IF="${NETWORK1}${VLAN1}${MAC1}${MODEL1} ${TAP1}${IFNAME1}${VLAN_TAP1}${SCRIPT1}"
	;;
	*)
		nic_model
		
		NETWORK1="-net nic" 
		VLAN1=",vlan=0" 
		MAC1=",macaddr=${MACADDR}" 
		USER1="-net user" 
		VLAN_USER1=",vlan=0" 
		HOSTNAME1= 
		MODEL1=",model=${NIC_MODEL}"
		IF="-net nic,vlan=0,macaddr=${MACADDR},model=${NIC_MODEL} -net user,vlan=0"
	;;
esac

NET_CON=$IF 
