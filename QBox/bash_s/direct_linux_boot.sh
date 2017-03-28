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

. ${LIB_DIR}/include

if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${INIT_SH} || NOT_DEFINE ${BASIC_UTILS_H}; then
	. ${LIB_DIR}/include '%%IMPORT%%' 'init.sh'
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 

if NOT_DEFINE ${ERROR_H}; then
	. ${LIB_DIR}/include '<error.h>'
fi 


  
let test=1
echo ${GO}
exit 0
#while [ $test -eq 1 ]; do 
	exec 3>&1
		value=$(${DIALOG} \
				--no-shadow --trim --ok-label "Boot" --output-separator "|" --form "Linux Direct Boot" ${HEIGHT} ${WIDTH} 13 \
				"Machine Name:" 2 2 "" 3 2 $((WIDTH-8)) 50 "Kernel Image:" 5 2 "" 6 2 $((WIDTH-8)) 50 "Initial Ram Disk:" 8 2 "" 9 2 $((WIDTH-8)) 50 \
				"Kernel Commad Line:" 11 2 "" 12 2 $((WIDTH-8)) 50 2>&1 1>&3)
			
			let "test_return=$?"
	exec 3>&-
			
			
	case ${test_return} in 
		${DIALOG_OK})
			
			VM_NAME=$(String_to_Upper ${value%%|*})
			KERNEL=$(echo ${value} | cut -d '|' -f2)
			INITRD=$(echo ${value} | cut -d '|' -f3)
			KERNEL_CMD=$(echo $value | cut -d "|" -f4)
			
#			KERNEL=`echo $2 | gawk -F "|" '{print $2}'` && KERNEL="-kernel ${KERNEL}"
#			INITRD=`echo $2 | gawk -F "|" '{print $3}'` && INITRD="-initrd ${INITRD}"
#			KERNEL_CMD=`echo $2 | gawk -F "|" '{print $4}'` && KERNEL_CMD="-append ${KERNEL_CMD}"
		
#			[ "${VM_NAME}" = "" ] && VM_NAME=MY_VM$$ || [ "`unique_vm_name $VM_NAME`" != "" ] && VM_NAME=MY_VM$$
			let "TEST_ERROR_OCURRED=${SUCCESS}"
			
			while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do 
				
				error_func_display $(err_str "VM_NAME:${STRERROR[vm_name]}:is_VMName_unique")
				TEST_ERROR_OCURRED=$?
				
				[[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]] && {
					exec 3>&1
						value=$(${DIALOG} \
							--trim --colors --form "\Zb\Z0Name Not Unique\Zn\ZB\nThe name of the VM should be unique.The name should not \
							contain \Zb\Z0white spaces\Zn\ZB and \"\Zb\Z0|\Zn\ZB\"." $((HEIGHT-5)) $((WIDTH-17)) 3 \
							"Name:" 2 2 "" 2 7 $((WIDTH-26)) 18 2>&1 1>&3)
					
						let "test_return=$?"
					exec 3>&-
				}
				
			done
			
#			HD_IMG=${VM_NAME}_linuz.img
#			qvm_name=${VM_NAME}_linuz.qvm
#			VM_NAME=`echo ${VM_NAME} | gawk '{print toupper($0)}'` && VM_NAME="-name $VM_NAME"
#		
#			test_cmd=`echo ${KERNEL_CMD} | gawk '{print $2}'` && [ "$test_cmd" = "" ] && KERNEL_CMD=""
#		
#			bash ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} % % % % % % % % \
#			%${KERNEL} %${INITRD} % % % % %${KERNEL_CMD} % %
#		
#			bash ${QBOX_DIR}/bash_s/qemu-bootfile-reader.sh $qvm_name linuz
		;;
	esac
#done
