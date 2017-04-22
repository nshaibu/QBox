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
. ${LIB_DIR}/import '<strings_definitions.h>'

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
				2) 
					#TODO @ Network configurations module
					
					network_conf_completed=${SUCCESS}
				;;
				3) 
					echo
					DEFINE __CMDLINE__
					_check_configured ${basic_conf_completed}:"1._Basic_Configurations_|" ${network_conf_completed}:"2._Network_Configurations_|"
					let _return=$?
					UNDEFINE __CMDLINE__
					read
					[ $_return -ne ${SUCCESS} ] && {
					echo
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
					
					if check_is_set ${Disk_Name}; then 
						HD_BI_IMG="-hda ${Disk_Name}"
						VM_CDROM="-cdrom ${VM_CDROM}"
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
					}
				;;
				*)
					clear
					echo "wrong Option" ;;
			esac
		;;
		0) break ;;
	esac
done
