#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Boot Linux kernel directly
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

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include '<random_uid.h>'
. ${LIB_DIR}/import '<init.h>'

DEFINE DIRECT_LINUX_BOOT


if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${INIT_SH} || NOT_DEFINE ${BASIC_UTILS_H}; then
	#${LIB_DIR}/include "%%IMPORT%%" 'init.sh'
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 

if NOT_DEFINE ${ERROR_H} || NOT_DEFINE ${ARCHITECTURE_H} || NOT_DEFINE ${BOOT_SYSTEM_H}; then
	. ${LIB_DIR}/include '<error.h>'
	. ${LIB_DIR}/include '<architecture.h>'
	. ${LIB_DIR}/include '<boot_system.h>'
fi 


Disk_Name=${RANDOM_UID}.img
let "_save_=${FAILURE}"

while : ; do 
	exec 3>&1
		value=$(${DIALOG} \
				--no-shadow --trim --default-button "ok" --cancel-label "back"  --ok-label "Boot" --output-separator "|" --form "Linux Direct Boot" \
				${HEIGHT} ${WIDTH} 11 "Machine Name:" 1 2 "" 2 2 $((WIDTH-8)) 50 "Kernel Image:" 4 2 "" 5 2 $((WIDTH-8)) 50 \
				"Initial Ram Disk:" 7 2 "" 8 2 $((WIDTH-8)) 50 "Kernel Commad Line:" 10 2 "" 11 2 $((WIDTH-8)) 50 2>&1 1>&3)
			
			let "test_return=$?"
	exec 3>&-
			
			
	case ${test_return} in 
		${DIALOG_OK})
			
			VM_NAME=$(String_to_Upper ${value%%|*})
			KERNEL=$(echo ${value} | cut -d '|' -f2)
			INITRD=$(echo ${value} | cut -d '|' -f3)
			KERNEL_CMD=$(echo ${value} | cut -d "|" -f4)
			
			KERNEL_CMD="-append ${KERNEL_CMD}"
			
			#----------------Verify unique name-----------------------------
			error_func_display $(err_str "VM_NAME:${STRERROR[vm_name]}:is_VMName_unique")
			let "TEST_ERROR_OCURRED=$?"
				
			while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do 
				
				exec 3>&1
					value=$(${DIALOG} \
						--trim --colors --nocancel --form "\Zb\Z1Name not unique\Zn\ZB\nThe name of the VM should be unique.The name should not \
						contain \Zb\Z0white spaces\Zn\ZB and \"\Zb\Z0|\Zn\ZB\"." $((HEIGHT-3)) $((WIDTH-12)) 3 \
						"Name:" 2 2 "" 2 7 $((WIDTH-26)) 18 2>&1 1>&3)
						
				exec 3>&-
					
				VM_NAME=$(String_to_Upper ${value}) 
				
				error_func_display $(err_str "VM_NAME:${STRERROR[vm_name]}:is_VMName_unique")
				let "TEST_ERROR_OCURRED=$?"	
				
			done
			
			VM_NAME="-name ${VM_NAME}"
			
			#----------------------------kernel image ---------------------
			error_func_display $(err_str "KERNEL:${STRERROR[KERNEL]}:check_is_file")
			let "TEST_ERROR_OCURRED=$?"
			
			while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do 
				exec 3>&1
					value=`${DIALOG} \
						--no-shadow --colors --nocancel --clear --title "\Zb\Z1Select a kernel image\Zn\ZB" \
						--fselect $HOME/ 10 50 2>&1 1>&3`
				exec 3>&-
				
				KERNEL=${value}
				
				error_func_display $(err_str "KERNEL:${STRERROR[KERNEL]}:check_is_file")
				let "TEST_ERROR_OCURRED=$?"
			done 
			
			KERNEL="-kernel ${KERNEL}"
			
			#----------------------initial ram disk--------------------------
			error_func_display $(err_str "INITRD:${STRERROR[INITRD]}:check_is_iso_file") $(err_str "INITRD:${STRERROR[INITRD]}:check_is_file")
			let "TEST_ERROR_OCURRED=$?"
			
			while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do 
				exec 3>&1
					value=`${DIALOG} \
						--no-shadow --colors --nocancel --clear --title "\Zb\Z1Select a kernel image\Zn\ZB" \
						--fselect $HOME/ 10 50 2>&1 1>&3`
				exec 3>&-	
				
				INITRD=${value}
				
				error_func_display $(err_str "INITRD:${STRERROR[INITRD]}:check_is_iso_file") $(err_str "INITRD:${STRERROR[INITRD]}:check_is_file")
				let "TEST_ERROR_OCURRED=$?"	
			done 
			
			INITRD="-initrd ${INITRD}"
			
			#---------------------append---------------------------------
			KERNEL_CMD="-append ${KERNEL_CMD}"
			
			#--------------save--------------------------------
			exec 3>&1
				value=`${DIALOG} \
					--no-shadow --defaultno --colors --title "\Zb\Z0Direct Linux Boot\Zn\ZB" \
					--yesno "\Zb\Z0Save VM\Zn\ZB\nDo you want to save this Virtual Machine ? Saving the VM will add an entry to the VM's database. This will allow you to boot the kernel without going through this steps again. \n\nThe default is \Zb\Z0NO\Zn\ZB" ${HEIGHT} ${WIDTH} 2>&1 1>&3`
			exec 3>&-	
				
			case ${value} in 
				${DIALOG_OK}) _save_=${SUCCESS} ;;
				${DIALOG_CANCEL}) _save_=${FAILURE} ;;
			esac
			
			detect_architecture "GLOBBING"
			architecture_type_choice $?
			
			boot_system ${_save_}

		;;
		${DIALOG_CANCEL}) break ;;
	esac
done
