#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Create Virtual Machines 
#-------------------------------------------------------------------------------------------
# This is a free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your option) 
# any later version.

# This is distributed in the hopes that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#===========================================================================================


trap 'rm -f ${TEMP_FOLDER}/.tmp.tt ${TEMP_FOLDER}/.find.tt ${TEMP_FOLDER}/.arhfind.tt rm -f ${TEMP_FOLDER}/.test_tap_exit.tt 2>/dev/null && export SDL_VIDEO_X11_DGAMOUSE=" " ' EXIT


##global variables
BOOT_ORDER=""
HD_IMG=""
HD_BI_IMG="" ##booting disk images
HD_IMG_DIR=$HOME/.img_qemubox ##contains harddisk images
VM_PID=$$
VM_NAME=""
NET_CON="" ##for networking
RAM_SIZE=""
QEMU=""
QEMU_PATH=""
QEMU_SOUND=""
QEMU_GRAPH=""
QEMU_USB="-usb"
QDB_FOLDER=${HD_IMG_DIR}/.qdb ##qbox database files location
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
VM_CDROM=""
NUM_CPU="-cpu host -smp 1"
KVM_ENABLE=""
BOOT_DIR=${HD_IMG_DIR}/.qemuboot ## contain boot files
LOG_DIR=${HD_IMG_DIR}/logs_dir
PID_FILE=${TEMP_FOLDER}/.pid

QBOX_DIR=/usr/local/bin/QBox
QEMU_DSKIMG_CREATOR=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-img`

#Isdigit return
declare -r SUCCESS=0
declare -r FAILURE=1

export SDL_VIDEO_X11_DGAMOUSE=0 ##to prevent qemu cursor from been difficult to control

#Generate random values
rand=`${QBOX_DIR}/bin/qemubox_random 100`
ra=`expr $$ % 60`


##Test whether input is char 
function isalpha(){
	if [ -z "$1" ]; then
		return 	$FAILURE
	fi 
	
	case "$1" in 
		[a-zA-Z]|[a-zA-Z]*) return $SUCCESS ;;
		*)	return $FAILURE ;;
	esac
}


function check_description_qdb_consistancy(){
	
	declare -a ARR_DESCRIPTION=(`cut -d "|" -f1 ${QDB_FOLDER}/description.qdb`)
	
	if [[ -n $ARR_DESCRIPTION ]]; then
		
		for i in ${ARR_DESCRIPTION[@]}
		do 
			Empty=`gawk -F "|" -v var="^$i\$" '$1 ~ var {print $1}' ${QDB_FOLDER}/vms.qdb`
			
			if [[ -n $Empty ]]; then
				name="^$i\$"
				gawk -F "|" -v var=$name '$1 !~ var {print $0}' ${QDB_FOLDER}/description.qdb 1>${TEMP_FOLDER}/vms.tt
				##replace black or space character with newline character
				sed -e 's/[[:blank:]]\+/\n/g' ${TEMP_FOLDER}/vms.tt 2>/dev/null 1>${QDB_FOLDER}/description.qdb
				rm -f ${TEMP_FOLDER}/vms.tt 2>/dev/null				
				break
			fi 
		done
	fi 
}


function yes_no()
{
	read -n 1 resp
	case "$resp" in 
		[Yy]|[Yy][Ee][Ss]) echo 0;;
		*) echo 1 ;;
	esac
}

##logger_func
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


##unique for the vms. The name is used as the primary key for vms database
function unique_vmname(){
	local search="^$1\$"
	local unique=$(gawk -F "|" -v var=$search '$1 ~ var {print $1}' ${QDB_FOLDER}/vms.qdb 2>/dev/null)
	echo $unique
}

##tap interface destructor
stop_tap_if()
{
	sudo tunctl -d ${TAP_NAME} 2>${TEMP_FOLDER}/.error.tt
		logger_logging
	
	sudo ifconfig br0 down 2>${TEMP_FOLDER}/.error.tt
		logger_logging
	sudo brctl delbr br0 2>${TEMP_FOLDER}/.error.tt
		logger_logging
	echo "stopping bridging interface">${TEMP_FOLDER}/.error.tt
	logger_logging
}


#############################################
#				BOOT DEVICE					#
#############################################
function boot_device_used()
{
	printf "%s\n" "[1]Choose the boot media to used"
	printf "%s\n" "   ->Options:[CDROM        ---> use OS CD ROM]" \
	              "             [iso[DEFAULT] ---> use OS iso file]"
	read device
	
	case $device in 
		[Cc][Dd][Rr][Oo][Mm]|[Cc][Dd]) 
			VM_CDROM="-cdrom /dev/cdrom" 
			echo -e "\t\n[2]Insert the disk in the host computer and press any key"
			read ent
			arch_type_use ;;
		*) VM_CDROM="";; ##This is for just making sure that as long as VM_CDROM is empty it means the user is using an iso file
	esac
}


#########################################
#				Boot VM 				#
########################################
function boot_func(){

	if [ -z "$VM_CDROM" ];then
	
		isotmp=$1
		
		OLDIFS=$IFS
		IFS="-"
		set $1
		
		##Generates random name and location for the virtual harddisk
		HD_IMG=${HOME}/.img_qemubox/qbox$3box_$rand${ra}.img
		HD_BI_IMG="-hda ${HD_IMG}"
			
			
			IFS=$OLDIFS
			printf "%s\n" "[1]Creating new disk image..." && sleep 1 & echo
			
			if [[ ${DSKIMG} != "raw" ]]; then
				${QEMU_DSKIMG_CREATOR} create -f ${DSKIMG} ${HD_IMG} ${DSKSIZE} 2>${TEMP_FOLDER}/.error.tt 
			else 
				${QEMU_DSKIMG_CREATOR} create -f ${DSKIMG} -o size=${DSKSIZE} ${HD_IMG} 2>${TEMP_FOLDER}/.error.tt 
			fi 
			
			##system errror logger
			logger_logging
			
			printf "%s\n" "[2]Installing..." && sleep 1
			
			${QEMU} ${VM_NAME} ${NUM_CPU} ${RAM_SIZE} ${NET_CON} ${QEMU_GRAPH} ${QEMU_SOUND} ${QEMU_USB} \
			${HD_BI_IMG} -cdrom $isotmp ${KVM_ENABLE} ${BOOT_ORDER} 2>${TEMP_FOLDER}/.error.tt
			
			##system Error logger
			logger_logging
				
				
			printf "%s" "[3]Do you want to save this VM[yes/no]? "
			rezult=$(yes_no)
			if [ $rezult -eq 0 ]; then
				##Generates boot files containing all the configurations
				if [ -f ${TEMP_FOLDER}/.test_tap_exit.tt ]; then ##if file exist then remove ${NET_CON}
					if ! [ -d ${TAP_DIR} ]; then
						mkdir ${TAP_DIR}
					fi
					
					##Stop bridging and tap interface
					stop_tap_if
					NET_CON=""
					
					##Generates boot file naming it with the name of the virtual hard disk already created
					eval ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
					%${VGA} %${DISPLAY} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${HOSTNAME0} %${TAP0} \
					%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
					%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${HOSTNAME1} %${TAP1} \
					%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
					%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${HOSTNAME2} %${TAP2} \
					%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
					%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${HOSTNAME3} %${TAP3} \
					%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
					%${MCAST3} %${SMB_SERVER} %${REDIRECT} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} % % %${QEMU_KEYBOARD} \
					%${QEMU_FULLSCREEN} % %${SNAP_OT} % % %
					
					rm -f ${TEMP_FOLDER}/.test_tap_exit.tt 2>/dev/null
					
				else
					##generate boot file
					eval ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
					%${VGA} %${DISPLAY} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${HOSTNAME0} %${TAP0} \
					%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
					%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${HOSTNAME1} %${TAP1} \
					%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
					%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${HOSTNAME2} %${TAP2} \
					%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
					%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${HOSTNAME3} %${TAP3} \
					%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
					%${MCAST3} %${SMB_SERVER} %${REDIRECT} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} % % %${QEMU_KEYBOARD} \
					%${QEMU_FULLSCREEN} % %${SNAP_OT} % % %
				fi
			else
				rm -f ${HD_IMG}
			fi
		else
			##Generate random names for the virtual harddisk
			HD_IMG=$HOME/.img_qemubox/qemubox_$rand${ra}.img
			HD_BI_IMG="-hda ${HD_IMG}"
			printf "%s\n" "[1]Creating new harddisk image..." && echo
				
				if [[ ${DSKIMG} != "raw" ]]; then
					${QEMU_DSKIMG_CREATOR} create -f ${DSKIMG} ${HD_IMG} ${DSKSIZE} 2>${TEMP_FOLDER}/.error.tt 
				else 
					${QEMU_DSKIMG_CREATOR} create -f ${DSKIMG} -o size=${DSKSIZE} ${HD_IMG} 2>${TEMP_FOLDER}/.error.tt 
				fi 
				  ##System error logger
				  logger_logging
				  echo && printf "%s\n" "[2]Booting for installation..." && sleep 1
				  
				  ${QEMU} ${VM_NAME} ${NUM_CPU} ${RAM_SIZE} ${NET_CON} ${QEMU_GRAPH} ${QEMU_SOUND} \
				  ${QEMU_USB} ${HD_BI_IMG} ${VM_CDROM} ${KVM_ENABLE} ${BOOT_ORDER} 2>${TEMP_FOLDER}/.error.tt
				  
				  logger_logging
				  
			printf "%s" "[3]Do you want to save this VM[yes/no]? "
			rezult=$(yes_no)
			if [ $rezult -eq 0 ]; then
				##Generates boot files containing all the configurations
				if [ -f ${TEMP_FOLDER}/.test_tap_exit.tt ]; then ##if file exist then remove ${NET_CON}
					[ ! -d ${TAP_DIR} ] && mkdir ${TAP_DIR}
					
					##Stop bridging and tap interface
					stop_tap_if
					NET_CON=""
					
					eval ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
					%${VGA} %${DISPLAY} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${HOSTNAME0} %${TAP0} \
					%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
					%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${HOSTNAME1} %${TAP1} \
					%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
					%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${HOSTNAME2} %${TAP2} \
					%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
					%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${HOSTNAME3} %${TAP3} \
					%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
					%${MCAST3} %${SMB_SERVER} %${REDIRECT} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} % % %${QEMU_KEYBOARD} \
					%${QEMU_FULLSCREEN} % %${SNAP_OT} % % %
					
					rm -f ${TEMP_FOLDER}/.test_tap_exit.tt
					
				else
					eval ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
					%${VGA} %${DISPLAY} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${HOSTNAME0} %${TAP0} \
					%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
					%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${HOSTNAME1} %${TAP1} \
					%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
					%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${HOSTNAME2} %${TAP2} \
					%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
					%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${HOSTNAME3} %${TAP3} \
					%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
					%${MCAST3} %${SMB_SERVER} %${REDIRECT} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} % % %${QEMU_KEYBOARD} \
					%${QEMU_FULLSCREEN} % %${SNAP_OT} % % %
				fi
			else
				rm -f ${HD_IMG}
			fi
		fi
	return 0
}


function func_install(){
	clear
	tput bold
	echo -e "\t\t\tQBox VM Creation Menu\n"
	tput sgr0
	
	echo -e "\t1. General Configurations"
	echo -e "\t2  System Configurations"
	echo -e "\t3. Audio Configurations"
	echo -e "\t4. Display Configurations"
	echo -e "\t5. Network Configurations"
	echo -e "\t0. Back \u2b05"
	echo -e "\n\t6. Choose the boot media to use"
	echo -e "\t7. Boot VM \n\n"
	
	echo -en "\t\tEnter Option: "
	read -n 1 opt
}

printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))
		
		
while true;
do 
	clear 
	
	func_install 
	check_description_qdb_consistancy
	
	case $opt in 
		0) break ;;
		1)
			echo
			read -p "[1]Enter a name for your VM[ENTER] " VM_NAME
			VM_NAME=$(echo $VM_NAME | awk '{print toupper($0)}') ##capitalise name
			
			DES_NAME=$VM_NAME
			##making sure that each vm has a unique name 
			if [ -z "${VM_NAME}" ]; then
				VM_NAME="-name MY_VM$$" 
			else
				
				while [ "$(unique_vmname ${VM_NAME})" != "" ]; do 
					echo -n "Name already in use "
					read VM_NAME
					VM_NAME=$(echo $VM_NAME | awk '{print toupper($0)}')
				done
				VM_NAME="-name $VM_NAME"
			fi 
			
			echo
			
			source ${QBOX_DIR}/bash_s/qbox_ostype_info.sh 
			echo "${DES_NAME}|${OS_VERSION}">>${QDB_FOLDER}/description.qdb
		;;
		2) 
			echo
			printf "%s\n" "[1]Enter the type of disk image to create for the VM[Enter] "
			printf "%s\n" "   Options:[1 ---------------> qcow2 ]" \
						  "           [2 ---------------> raw   ] "
			read -n 1 xvar
			echo
			
			case "$xvar" in 
				1) DSKIMG="qcow2";;
				2)	DSKIMG="raw" ;;
				*)
					echo "   ->using qcow2 as default"
					DSKIMG="qcow2"
				;;
			esac
	
			read -p "[2]Enter size for the disk image[Recommended:${RECOM_DISK_SIZE}] " DSKSIZE
			echo
			
			[ -z "${DSKSIZE}" ] && DSKSIZE=${RECOM_DISK_SIZE} && echo "   ->Disk size of ${RECOM_DISK_SIZE} was used"
	
			read -p "[3]Enter the ram size[Recommended:${RECOM_RAM_SIZE}] " RAMSIZE
			echo
				
			if [ -z "${RAMSIZE}" ]
			then
				RAM_SIZE="-m ${RECOM_RAM_SIZE}"
				echo "   ->Ram size of ${RECOM_RAM_SIZE} was used"
			else
				POS_OF_LAST_CHR=$(( ${#RAMSIZE} - 1 ))
				
				if isalpha ${RAMSIZE:$POS_OF_LAST_CHR} ; then
					RAM_SIZE="-m ${RAMSIZE}"
				else 
					RAM_SIZE="-m ${RAMSIZE}M"
				fi 
			fi
			
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%SNAPSHOT%"
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%CPU%"
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%USB%"
			
		;;
		3) source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%SOUND%" ;;
		4)
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%DISPLAY%"
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%KEYBOARD%"
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%FULLSCREEN%"
		;;
		5) source ${QBOX_DIR}/bash_s/qemu-net-box.sh ;;
		6)
			echo
			boot_device_used
			
			if [ -z "$VM_CDROM" ];then
				printf "%s\n" "[2]Enter the name of the iso file you want to install" 
					echo "or [Enter] to search for iso files"
					read QEMU_PATH
					while [ -z ${QEMU_PATH} ]
					do
						echo "   ->The system will check for iso files in [${HOME}]"
						echo "   ->checking ... " && echo
						for i in $(find ${HOME} -depth -type f -a -name "*.iso" -print 2>>/dev/null)
						do 
							
							echo "     ->Found $(basename $i)" && sleep 1
						done
						echo
						[ "$i" = "" ] && break 
						printf "%s" "[3]Choose an iso from above "
						read QEMU_PATH
					done
					
					find ${HOME} -depth -name ${QEMU_PATH} -print 1>${TEMP_FOLDER}/.find.tt 2>/dev/null
					temp=$(cat ${TEMP_FOLDER}/.find.tt 2>/dev/null)
					if [ "$temp" != "" ]
					then
						echo "   ->Searching [${HOME}] for ${QEMU_PATH}..." && sleep 1
						echo "   ->FOUND @ [$(cat ${TEMP_FOLDER}/.find.tt)] " && sleep 1
						echo "   ->Setting path to [$(cat ${TEMP_FOLDER}/.find.tt)]" && sleep 1
						QEMU_PATH=$(cat ${TEMP_FOLDER}/.find.tt)
					else
						echo "  ->iso file not found in the [${HOME}] "
						echo "  ->Copy the iso file to [${HOME}] or It's sub-directory "
						exit 1
					fi
							
							
				if [ -z ${QEMU} ]; then
					ARCH_FOR_ISO=`basename $(cat ${TEMP_FOLDER}/.find.tt)` #> ${TEMP_FOLDER}/.arhfind.tt
					
					##awk script to help determine the architecture to use for the iso file
					ARCH=`echo ${ARCH_FOR_ISO} | gawk -f ${QBOX_DIR}/awk/qemu-s-arch.awk` # ${TEMP_FOLDER}/.arhfind.tt)
										
					if [ -n ${ARCH} ]; then
							
						case ${ARCH} in 
							x86_64|x86|amd64|i686) 
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-x86_64`
								BOOT_ORDER="-boot order=d"
								KVM_ENABLE="-enable-kvm"
								printf "%s\n" "   ->System determined x86_64 architecture. Continue with x86_64?[yes/No]"
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							i386|x86_32)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-i386`
								BOOT_ORDER="-boot order=d"
								KVM_ENABLE="-enable-kvm"
								printf "%s" "   ->System determined x86_32 architecture. Continue with x86_32[yes/No]? "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							arm)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-arm`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined arm architecture. Continue with arm?[yes/No] "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							ppc)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined ppc architecture. Continue with ppc?[yes/No]? "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							ppc64)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc64`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined ppc64. Continue with ppc64?[yes/No] "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							sparc)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined sparc32. Continue with sparc32?[yes/No] "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							sparc64)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc64`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined sparc64. Continue with sparc64?[yes/No] "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							mips)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mips`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined mips32. Continue with mips32?[yes/No] "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							mipsel)
								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mipsel`
								BOOT_ORDER="-boot order=d"
								printf "%s\n" "   ->System determined mips64. Continue with mips64?[yes/No] "
								result=$(yes_no)
								
								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
							;;
							*) 
								echo -e "\n   ->Architecture type detection for [$QEMU_PATH] failed\n" 
								source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE% 
							;;
						esac
					else
						echo -e "\n   ->Architecture type detection for [$QEMU_PATH] failed\n" 
						source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
					fi
				else
					source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE% 
				fi
			fi ##for con	1dition the conditon VM_CDROM != /dev/cdrom]
				rm -f ${TEMP_FOLDER}/.find.tt ${TEMP_FOLDER}/.arhfind.tt 2>/dev/null
		;;
		7) 
			tput setaf 9
			if [ -z "${QEMU_PATH}" ]; then
				echo -e "\n\n\t No boot media selected" 
			else
				tput sgr0
				boot_func $QEMU_PATH
			fi 
			tput sgr0
		;;
		*)
				clear
				echo "wrong Option";;
		esac
		
		echo -en "\n\n\t\t\tHit any key to continue"
		read -n 1 line
done

export SDL_VIDEO_X11_DGAMOUSE=" "
exit 0
