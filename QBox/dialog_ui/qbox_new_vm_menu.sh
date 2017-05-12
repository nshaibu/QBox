#!/bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: VM creations menu
#-------------------------------------------------------------------------------------------
# This is is free software; you can redistribute it and/or modify it
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

: ${LIB_DIR:=/usr/local/bin/QBox/include_dir}

. ${LIB_DIR}/include
. ${LIB_DIR}/import '<init.h>'

if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${BASIC_UTILS_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 

while : ; do 

	exec 3>&1 
		value=$(${DIALOG} \
				--no-shadow --cancel-label "Back" --colors --title "\Zb\Z0Create New Virtual Machine\Zn\ZB" \
				--menu "\Zb\Z0Create New VM\Zn\ZB\nThis menu will help you configure the VM." ${HEIGHT} ${WIDTH} 2 1 "Guided Mode" \
				2 "Expert Mode"  2>&1 1>&3)
				
		let "test_return=$?"
	exec 3>&-
	
	case ${test_return} in 
		${DIALOG_OK})
			[ ${value} -eq 1 ] && {
				. ${LIB_DIR}/include '<disk_details.h>'
				. ${LIB_DIR}/include '<network.h>'
				
				if NOT_DEFINE ${ARCHITECTURE_H} || NOT_DEFINE ${ERROR_H}; then 
					. ${LIB_DIR}/include '<architecture.h>'
					. ${LIB_DIR}/include '<error.h>'
				fi 
				
				printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))
				
				DEFINE GUIDED_MODE_BOOT_VM
				. ${DIALOG_DIR}/qbox_create_vm.sh
				
				UNDEFINE GUIDED_MODE_BOOT_VM
				
				DISK_SIZE=${RECOM_DISK_SIZE}
				RAM_SIZE="-m ${RECOM_RAM_SIZE}"
				
				#-----network-------
				set_parameters 0 ",vlan=0" ",macaddr=${MACADDR}" ",model=e1000" "-net_user" ",vlan=0"
				default_network="${NETWORK0}${VLAN0}${MAC}${MODEL0} ${USER0}${VLAN_USER0}"
				
				#----display--------
				VGA="-vga cirrus"
				DISPLAY_="-display sdl"
				QEMU_GRAPH="${VGA} ${DISPLAY_}"
				
				#----number of cpu--
				CPU="-cpu host"
				CORE="-smp 1"
				NUM_CPU="${CPU} ${CORE}"
				
				
				until check_is_file $value && check_is_iso_file $value ; do
					exec 3>&1
						value=`${DIALOG} \
							--no-shadow --colors --clear --title "\Zb\Z0Select a file\Zn\ZB" \
							--fselect $HOME/ 10 50 2>&1 1>&3`
							let _return=$?
					exec 3>&-
					#Sat 18 Feb 2017 05:55:42 PM GMT 
					[ $_return -eq ${DIALOG_CANCEL} ] && break 2
				done
				
				DEFINE GUIDED_MODE_BOOT_VM
				VM_CDROM=$value
				detect_architecture ${VM_CDROM}
				architecture_type_choice $?
				
				UNDEFINE GUIDED_MODE_BOOT_VM
				
				declare -a CONFIG_PARAMS=("QEMU" "VM_NAME" "DISK_SIZE" "NUM_CPU" "RAM_SIZE" "Disk_Name" "default_network" )
				
				let "issaved=${FAILURE}, i=0, i_var=0, percentage=0"
				let "move_boot=${FAILURE}, move_save=${FAILURE}, move_creat_hd=${FAILURE}"
				
				{
					while : ; do 
						#-----------check param set ---------------------
						[ ${move_boot} -eq ${FAILURE} ] && [ ${move_save} -eq ${FAILURE} ] && [ ${move_creat_hd} -eq ${FAILURE} ] && {
							eval tmp_param='$'${CONFIG_PARAMS[$i]}
							
							if check_is_set ${tmp_param}; then 
								echo "XXX"
								echo $percentage
								echo "checking $(String_to_Lower ${CONFIG_PARAMS[$i]}) ($percentage%)"
								echo "XXX"
								
								[ $i -eq ${#CONFIG_PARAMS[@]} ] && { move_creat_hd=${SUCCESS}; }
								(( i_var=i ))
							else
								let "err_code=${ERR_VALUE_NOT_SET}"
								break
							fi 
						}
						#-----------creating harddisk image--------------
						[ ${move_creat_hd} -eq ${SUCCESS} ] && [ ${move_boot} -eq ${FAILURE} ] && [ ${move_save} -eq ${FAILURE} ] && {
							echo "XXX"
							echo $percentage
							echo "creating harddisk ($percentage%)"
							echo "XXX"
							
							if disk_image_creation 1 ${Disk_Name} ${DISK_SIZE}; then
								HD_BI_IMG="-hda ${Disk_Name}"
								VM_CDROM="-cdrom ${VM_CDROM}"
								move_boot=${SUCCESS}
							else 
								let "err_code=${ERR_IN_DISK_CREATION}"
								rm -f ${Disk_Name} 2>/dev/null
								break
							fi
							sleep 0.6 
						}
						#------------booting vm--------------------------
						[ ${move_boot} -eq ${SUCCESS} ] && [ ${move_creat_hd} -eq ${SUCCESS} ] && [ ${move_save} -eq ${FAILURE} ] && {
							echo "XXX"
							echo $percentage
							echo "Booting ${VM_NAME:6:18} ($percentage%)"
							echo "XXX"	
							
							${QEMU} ${VM_NAME} ${NUM_CPU} ${RAM_SIZE} ${default_network} ${QEMU_GRAPH} ${QEMU_SOUND} \
							${QEMU_USB} ${HD_BI_IMG} ${VM_CDROM} ${KVM_ENABLE} ${BOOT_ORDER} 2>${LOGS_FILE}
							
							[ $? -eq ${FAILURE} ] && { let "err_code = ${ERR_OCCURRED_DURING_BOOT}"; logger_logging ${LOGS_FILE}; break; }
							
							let "move_save=${SUCCESS}"
							sleep 0.6
						}
						#------------saving vm --------------------------
						[ ${move_boot} -eq ${SUCCESS} ] && [ ${move_creat_hd} -eq ${SUCCESS} ] && [ ${move_save} -eq ${SUCCESS} ] && {
							echo "XXX"
							echo $percentage
							echo "Saving ${VM_NAME:6:18} ($percentage%)"
							echo "XXX"	
				
							[ $issaved -ne ${SUCCESS} ] && {
								
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
								
								issaved=${SUCCESS}
							}
				
							sleep 0.3										
						}
						
						sleep 0.5
						(( i+=1 ))
						(( percentage=i * 100 / 14 + 8 ))
						
						[ ${percentage} -ge 100 ] && break
						
					done 
				} | ${DIALOG} --gauge "Please wait" 7 70 0
				
				perror ${err_code} __DIALOG__
				break
			
			} || {
				
				while : ; do 
					exec 3>&1
						value=$(${DIALOG} \
								--no-shadow --clear --extra-button --extra-label "Back" --colors --title "\Zb\Z0Create New Virtual Machine\Zn\ZB" \
								--menu "\Zb\Z0Create New VM\Zn\ZB\nThis menu will help you configure the VM." ${HEIGHT} ${WIDTH} 3 1 "Basic configurations" \
								2 "Network configurations" 3 "Select Boot device" 2>&1 1>&3)
	
						let "test_return=$?"
					exec 3>&-

					case ${test_return} in 
						${DIALOG_OK}) 
							if [[ $value -eq 1 ]]; then
								. ${DIALOG_DIR}/qbox_create_vm.sh 
							elif [[ $value -eq 2 ]]; then
								. ${DIALOG_DIR}/qbox_network_config.sh 
							elif [[ $value -eq 3 ]]; then
								. ${DIALOG_DIR}/qbox_boot_device.sh 
							fi 
						;;
						${DIALOG_BACK}) break ;;
					esac
				done
			
			}
		;;
		${DIALOG_CANCEL}) break ;;
	esac
done
