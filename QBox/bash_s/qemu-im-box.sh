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

: ${LIB_DIR:=$HOME/my_script/QB/QBox/include_dir}

. ${LIB_DIR}/include '<network.h>'
. ${LIB_DIR}/include '<architecture.h>'
. ${LIB_DIR}/include '<disk_details.h>'

. ${LIB_DIR}/import '<init.h>'
. ${LIB_DIR}/import '<qdb_database.h>'
. ${LIB_DIR}/import '<boot_vm.h>'
. ${LIB_DIR}/import '<var_definitions.h>'

if NOT_DEFINE ${BASIC_UTILS_H} || NOT_DEFINE ${TRUE_TEST_H} || NOT_DEFINE ${ERROR_H} ; then
	. ${LIB_DIR}/include '<basic_utils.h>'
	. ${LIB_DIR}/include '<true_test.h>'
	. ${LIB_DIR}/include '<error.h>'
fi 

let basic_conf_completed=${FAILURE}
let network_conf_completed=${FAILURE}

declare -a _hd_formats=("QCOW2(QEMU Copy-On-Write)" "RAW(Raw disk image format)" "QED(QEMU Enhanced Disk)" "VMDK(Virtual Machine Disk)" \
						"VDI(Virtual Disk Image)")

function get_vm_name() {
			let TEST_ERROR_OCURRED=${SUCCESS}
			
			while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do 
				echo 
				read -p "[$$]Enter a name for your Virtual Machine " vm_name
				vm_name=$(String_to_Upper ${vm_name})
			
				DEFINE __CMDLINE__
				error_func_display $(err_str "vm_name:${STRERROR[vm_name]}:is_VMName_unique") 
				TEST_ERROR_OCURRED=$?
				
				UNDEFINE __CMDLINE__
				
				[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ] && {
					let "TEST_ERROR_OCURRED=${SUCCESS}"
								
					VM_NAME="-name ${vm_name}" # set vm name 
					break
				}
			done
}


function func_install(){
	clear
	tput bold
	echo -e "\t\t\tQBox VM Creation Menu\n"
	tput sgr0
	echo -e "\t1. Guided Mode"
	echo -e "\t2. Expert Mode"
	echo -e "\t0. Back \u2b05 \n\n"
	
	echo -en "\t\tEnter Option: "
	read -n 1 opt
}

function _install_expert_mode() {
	clear
	tput bold
	echo -e "\t\t\tQBox VM Creation (Expert Mode)\n"
	tput sgr0
	
	echo -e "\t1. Basic configurations"
	echo -e "\t2  Network configurations"
	echo -e "\t3. Select Boot device"
	echo -e "\t0. Back \u2b05 \n\n"	
	
	echo -en "\t\tEnter Option: "
	read -n 1 opt	
}

printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))
		
		
while true; do 
	clear 
	
	func_install 
	
	case ${opt} in 
		1) 
			get_vm_name
			
			printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))
			
			. ${BASIC_BASH}/qbox_ostype_info.sh 
			
			DISK_SIZE=${RECOM_DISK_SIZE}
			RAM_SIZE="-m ${RECOM_RAM_SIZE}"
			
			#-----network-------
			set_parameters 0 ",vlan=0" ",macaddr=${MACADDR}" ",model=e1000" "-net_user" ",vlan=0"
			default_network="${NETWORK0}${VLAN0}${MAC}${MODEL0} ${USER0}${VLAN_USER0}"
			
			#----display--------
			VGA="-vga cirrus" && DISPLAY_="-display sdl"
			QEMU_GRAPH="${VGA} ${DISPLAY_}"
				
			#----number of cpu--
			CPU="-cpu host" && CORE="-smp 1"
			NUM_CPU="${CPU} ${CORE}"			
			
			let value=1
			until check_is_file $value && check_is_iso_file $value ; do
				echo -e $(get_string_by_name PROMPT_CHECKING_FOR_ISO)
				declare -a iso_files=( $(check_for_iso_files) )
				
				[ ${#iso_files[@]} -eq 0 ] && { perror ${NO_ISO_FILES} __CLI__; } || {
					echo -e "\tFound:"
					tput bold
					for (( index=0; index<${#iso_files[@]}; index++ )); do 
						echo -e "\t\t  $(( index+1 )).  ${iso_files[$index]}" && sleep 0.2
					done 
					tput sgr0
					
					echo -e $(get_string_by_name PROMPT_SPECIFY_PATH_TO_ISO)
					echo -e ""
					
					read -p "[$$]Choose an iso file " value
				}
			done 
			
			DEFINE __CMDLINE__
			DEFINE GUIDED_MODE_BOOT_VM
			
			VM_CDROM=$value
			detect_architecture ${VM_CDROM}
			architecture_type_choice $?		
			
			UNDEFINE GUIDED_MODE_BOOT_VM
			UNDEFINE __CMDLINE__
			
			echo -e "[$$]creating harddisk image..." && sleep 0.5
			if disk_image_creation 1 ${Disk_Name} ${DISK_SIZE}; then
				HD_BI_IMG="-hda ${Disk_Name}"
				VM_CDROM="-cdrom ${VM_CDROM}"
				move_boot=${SUCCESS}
			else 
				perror ${ERR_IN_DISK_CREATION}  __CLI__
				rm -f ${Disk_Name} 2>/dev/null
				exit ${FAILURE}
			fi	 
				
			echo -e "[$$]Booting Virtual Machine..."
			${QEMU} ${VM_NAME} ${NUM_CPU} ${RAM_SIZE} ${default_network} ${QEMU_GRAPH} ${QEMU_SOUND} \
			${QEMU_USB} ${HD_BI_IMG} ${VM_CDROM} ${KVM_ENABLE} ${BOOT_ORDER} 2>/dev/null
			
			[ $? -eq ${FAILURE} ] && { perror ${ERR_OCCURRED_DURING_BOOT} __CLI__; exit ${FAILURE}; }
			
			
			echo -e "[$$]Saving Virtual Machine..."
			bash ${BASIC_BASH}/qemu-bootfile-generator.sh ${Disk_Name} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
			%${VGA} %${DISPLAY_} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${REDIRECT0} %${TAP0} \
			%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
			%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${REDIRECT1} %${TAP1} \
			%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
			%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${REDIRECT2} %${TAP2} \
			%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
			%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${REDIRECT3} %${TAP3} \
			%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
			%${MCAST3} %${SMB_SERVER} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} %${KERNEL} %${INITRD} %${QEMU_KEYBOARD} \
			%${QEMU_FULLSCREEN} % %${SNAP_OT} %${KERNEL_CMD} % % #2>/dev/null			
			sleep 1.2
		;;
		2) 
			_install_expert_mode
			
			case ${opt} in 
				0) break ;;
				1) 
					
					echo
					DEFINE __CMDLINE__
					_test_already_configured ${basic_conf_completed}:"basic configurations"
					
					let _return=$?
					UNDEFINE __CMDLINE__
					#[ -z $_return ] && _return=${SUCCESS}
					[ $_return  -eq ${SUCCESS} ] && {
					
					get_vm_name
					. ${BASIC_BASH}/qbox_ostype_info.sh 
					
					let TEST_ERROR_OCURRED=${SUCCESS}
					until [[ ${TEST_ERROR_OCURRED} -eq ${FAILURE} ]]; do 
						echo -en $(get_string_by_name PROMPT_SIZE_OF_MEM "[Recommended:${RECOM_RAM_SIZE}]")
						read RAM_SIZE
						[ "${RAM_SIZE}" = "" ] && RAM_SIZE=${RECOM_RAM_SIZE}
						
						DEFINE __CMDLINE__
						error_func_display $(err_str "RAM_SIZE:${STRERROR[RAM_SIZE]}:disk_size_valid")
						TEST_ERROR_OCURRED=$?
						
						[ ${TEST_ERROR_OCURRED} -eq ${FAILURE} ] && {
							RAM_SIZE="-m $RAM_SIZE"
							
							UNDEFINE __CMDLINE__
						}
					done 
					
					echo
					let TEST_ERROR_OCURRED=${SUCCESS}
					
					until [[ ${TEST_ERROR_OCURRED} -eq ${FAILURE} ]]; do 
						echo -en $(get_string_by_name PROMPT_SIZE_OF_DISK "[Recommended:${RECOM_DISK_SIZE}]")
						read DISK_SIZE
						[ "${DISK_SIZE}" = "" ] && DISK_SIZE=${RECOM_DISK_SIZE}
						
						DEFINE __CMDLINE__
						
						error_func_display $(err_str "DISK_SIZE:${STRERROR[DSK_VALID_SIZE]}:disk_size_valid")
						TEST_ERROR_OCURRED=$?
						
						if [[ ${TEST_ERROR_OCURRED} -eq ${FAILURE} ]]; then
							tput bold
							echo -e $(get_string_by_name PROMPT_DISK_FORMATS)
							PS3="Choose type: "
							tput sgr0
							
							select option in "${_hd_formats[@]}"; do 
								case $option in 
									"QCOW2(QEMU Copy-On-Write)") 
										disk_image_creation 1 ${Disk_Name} ${DISK_SIZE} || {
											perror ${ERR_IN_DISK_CREATION} __CLI__
											rm ${Disk_Name} 2>/dev/null
										}
										
										break
									;;
									"RAW(Raw disk image format)") 
										disk_image_creation 2 ${Disk_Name} ${DISK_SIZE} || {
											perror ${ERR_IN_DISK_CREATION} __CLI__
											rm ${Disk_Name} 2>/dev/null
										}
										
										break					
									;;
									"QED(QEMU Enhanced Disk)") 
										disk_image_creation 3 ${Disk_Name} ${DISK_SIZE} || {
											perror ${ERR_IN_DISK_CREATION} __CLI__
											rm ${Disk_Name} 2>/dev/null
										}
										
										break				
									;;
									"VMDK(Virtual Machine Disk)") 
										disk_image_creation 4 ${Disk_Name} ${DISK_SIZE} || {
											perror ${ERR_IN_DISK_CREATION} __CLI__
											rm ${Disk_Name} 2>/dev/null
										}
										
										break
									;;
									"VDI(Virtual Disk Image)") 
										disk_image_creation 5 ${Disk_Name} ${DISK_SIZE} || {
											perror ${ERR_IN_DISK_CREATION} __CLI__
											rm ${Disk_Name} 2>/dev/null
										}
										
										break					
									;;
								esac
							done 
							
							UNDEFINE __CMDLINE__
						fi 
					done
					
					echo 
					echo -e $(get_string_by_name PROMPT_NUM_CPU_CORES)
					read -p "[${LINENO}:$$]~>" -n 1 numcore
					echo 
					
					case $numcore in 
						4|3|2) CORE="-smp $numcore" ;;
						*) CORE="-smp 1" ;;
					esac
					NUM_CPU="-cpu host ${CORE}"
					
					#-----disply------
					echo
					echo -e $(get_string_by_name PROMPT_DISPLAY)
					read -p "[${LINENO}:$$]~>" -n 1 sd
					echo 
					
					case "$sd" in 
						3)
							DISPLAY_="-display vnc=:${VNC_DISPLAY}"
							printf "%s\n" "To view your vm.Enter vncviewer ${IF_ADDR}:${VNC_PORT}"
						;;
						1) DISPLAY_="-display curses" ;;
						*) DISPLAY_="-display sdl" ;;
					esac
					
					echo
					echo -e $(get_string_by_name PROMPT_VIDEO_CARD)
					read -p "[${LINENO}:$$]~>" -n 1 vcard
					echo 
					
					case "$vcard" in 
						2) VGA="-vga std" ;;
						*) VGA="-vga cirrus" ;;
					esac
					
					QEMU_GRAPH="${VGA} ${DISPLAY_}"
					#-------usb-------------
					echo
					echo -e $(get_string_by_name PROMPT_USB_DEVICE)
					read -p "[${LINENO}:$$]~>" -n 1 usb
					echo 
					[ -z $usb ] && usb=1
					pointing_dev_choice $usb
					
					echo 
					echo -e $(get_string_by_name PROMPT_SOUND_MODULE)
					read -p "[${LINENO}:$$]~>" -n 1 snd
					
					echo 
					[ -z $snd ] && snd=1
					sound_drivers $snd
					
					basic_conf_completed=${SUCCESS}
					}
				;;
				2) ;;
				3) ;;
			esac
		;;
		0) break ;;
	esac
#	case $opt in 
#		0) break ;;
#		1)
#			echo
#			read -p "[1]Enter a name for your VM[ENTER] " VM_NAME
#			VM_NAME=$(echo $VM_NAME | awk '{print toupper($0)}') ##capitalise name
#			
#			DES_NAME=$VM_NAME
#			##making sure that each vm has a unique name 
#			if [ -z "${VM_NAME}" ]; then
#				VM_NAME="-name MY_VM$$" 
#			else
#				
#				while [ "$(unique_vmname ${VM_NAME})" != "" ]; do 
#					echo -n "Name already in use "
#					read VM_NAME
#					VM_NAME=$(echo $VM_NAME | awk '{print toupper($0)}')
#				done
#				VM_NAME="-name $VM_NAME"
#			fi 
#			
#			echo
#			
#			source ${QBOX_DIR}/bash_s/qbox_ostype_info.sh 
#			echo "${DES_NAME}|${OS_VERSION}">>${QDB_FOLDER}/description.qdb
#		;;
#		2) 
#			echo
#			printf "%s\n" "[1]Enter the type of disk image to create for the VM[Enter] "
#			printf "%s\n" "   Options:[1 ---------------> qcow2 ]" \
#						  "           [2 ---------------> raw   ] "
#			read -n 1 xvar
#			echo
#			
#			case "$xvar" in 
#				1) DSKIMG="qcow2";;
#				2)	DSKIMG="raw" ;;
#				*)
#					echo "   ->using qcow2 as default"
#					DSKIMG="qcow2"
#				;;
#			esac
#	
#			read -p "[2]Enter size for the disk image[Recommended:${RECOM_DISK_SIZE}] " DSKSIZE
#			echo
#			
#			[ -z "${DSKSIZE}" ] && DSKSIZE=${RECOM_DISK_SIZE} && echo "   ->Disk size of ${RECOM_DISK_SIZE} was used"
#	
#			read -p "[3]Enter the ram size[Recommended:${RECOM_RAM_SIZE}] " RAMSIZE
#			echo
#				
#			if [ -z "${RAMSIZE}" ]
#			then
#				RAM_SIZE="-m ${RECOM_RAM_SIZE}"
#				echo "   ->Ram size of ${RECOM_RAM_SIZE} was used"
#			else
#				POS_OF_LAST_CHR=$(( ${#RAMSIZE} - 1 ))
#				
#				if isalpha ${RAMSIZE:$POS_OF_LAST_CHR} ; then
#					RAM_SIZE="-m ${RAMSIZE}"
#				else 
#					RAM_SIZE="-m ${RAMSIZE}M"
#				fi 
#			fi
#			
#			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%SNAPSHOT%"
#			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%CPU%"
#			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%USB%"
#			
#		;;
#		3) source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%SOUND%" ;;
#		4)
#			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%DISPLAY%"
#			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%KEYBOARD%"
#			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh "%FULLSCREEN%"
#		;;
#		5) source ${QBOX_DIR}/bash_s/qemu-net-box.sh ;;
#		6)
#			echo
#			boot_device_used
#			
#			if [ -z "$VM_CDROM" ];then
#				printf "%s\n" "[2]Enter the name of the iso file you want to install" 
#					echo "or [Enter] to search for iso files"
#					read QEMU_PATH
#					while [ -z ${QEMU_PATH} ]
#					do
#						echo "   ->The system will check for iso files in [${HOME}]"
#						echo "   ->checking ... " && echo
#						for i in $(find ${HOME} -depth -type f -a -name "*.iso" -print 2>>/dev/null)
#						do 
#							
#							echo "     ->Found $(basename $i)" && sleep 1
#						done
#						echo
#						[ "$i" = "" ] && break 
#						printf "%s" "[3]Choose an iso from above "
#						read QEMU_PATH
#					done
#					
#					find ${HOME} -depth -name ${QEMU_PATH} -print 1>${TEMP_FOLDER}/.find.tt 2>/dev/null
#					temp=$(cat ${TEMP_FOLDER}/.find.tt 2>/dev/null)
#					if [ "$temp" != "" ]
#					then
#						echo "   ->Searching [${HOME}] for ${QEMU_PATH}..." && sleep 1
#						echo "   ->FOUND @ [$(cat ${TEMP_FOLDER}/.find.tt)] " && sleep 1
#						echo "   ->Setting path to [$(cat ${TEMP_FOLDER}/.find.tt)]" && sleep 1
#						QEMU_PATH=$(cat ${TEMP_FOLDER}/.find.tt)
#					else
#						echo "  ->iso file not found in the [${HOME}] "
#						echo "  ->Copy the iso file to [${HOME}] or It's sub-directory "
#						exit 1
#					fi
#							
#							
#				if [ -z ${QEMU} ]; then
#					ARCH_FOR_ISO=`basename $(cat ${TEMP_FOLDER}/.find.tt)` #> ${TEMP_FOLDER}/.arhfind.tt
#					
#					##awk script to help determine the architecture to use for the iso file
#					ARCH=`echo ${ARCH_FOR_ISO} | gawk -f ${QBOX_DIR}/awk/qemu-s-arch.awk` # ${TEMP_FOLDER}/.arhfind.tt)
#										
#					if [ -n ${ARCH} ]; then
#							
#						case ${ARCH} in 
#							x86_64|x86|amd64|i686) 
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-x86_64`
#								BOOT_ORDER="-boot order=d"
#								KVM_ENABLE="-enable-kvm"
#								printf "%s\n" "   ->System determined x86_64 architecture. Continue with x86_64?[yes/No]"
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							i386|x86_32)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-i386`
#								BOOT_ORDER="-boot order=d"
#								KVM_ENABLE="-enable-kvm"
#								printf "%s" "   ->System determined x86_32 architecture. Continue with x86_32[yes/No]? "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							arm)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-arm`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined arm architecture. Continue with arm?[yes/No] "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							ppc)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined ppc architecture. Continue with ppc?[yes/No]? "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							ppc64)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc64`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined ppc64. Continue with ppc64?[yes/No] "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							sparc)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined sparc32. Continue with sparc32?[yes/No] "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							sparc64)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc64`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined sparc64. Continue with sparc64?[yes/No] "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							mips)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mips`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined mips32. Continue with mips32?[yes/No] "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							mipsel)
#								QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mipsel`
#								BOOT_ORDER="-boot order=d"
#								printf "%s\n" "   ->System determined mips64. Continue with mips64?[yes/No] "
#								result=$(yes_no)
#								
#								[ $result -eq 1 ] && source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#							;;
#							*) 
#								echo -e "\n   ->Architecture type detection for [$QEMU_PATH] failed\n" 
#								source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE% 
#							;;
#						esac
#					else
#						echo -e "\n   ->Architecture type detection for [$QEMU_PATH] failed\n" 
#						source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE%
#					fi
#				else
#					source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE% 
#				fi
#			fi ##for con	1dition the conditon VM_CDROM != /dev/cdrom]
#				rm -f ${TEMP_FOLDER}/.find.tt ${TEMP_FOLDER}/.arhfind.tt 2>/dev/null
#		;;
#		7) 
#			tput setaf 9
#			if [ -z "${QEMU_PATH}" ]; then
#				echo -e "\n\n\t No boot media selected" 
#			else
#				tput sgr0
#				boot_func $QEMU_PATH
#			fi 
#			tput sgr0
#		;;
#		*)
#				clear
#				echo "wrong Option";;
#		esac
#		
#		echo -en "\n\n\t\t\tHit any key to continue"
#		read -n 1 line
done
