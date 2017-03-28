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

: ${DIALOG:=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% dialog`}

##unique for the vms. The name is used as the primary key for vms database
function unique_vm_name(){
	search="^$1\$"
	unique=$(gawk -F "|" -v var=$search '$1 ~ var {print $1}' ${QDB_FOLDER}/vms.qdb 2>/dev/null)
	echo $unique
}
  
let test=1

while [ $test -eq 1 ]; do 
	
	${DIALOG} \
			--no-shadow --nook --nocancel --title "Linux Direct Boot" --menu "Choose Architecture" 18 50 30 1 "PC,intel-8086(32bit)" \
			2 "PC,intel-8086(64bit)" 3 "PC,ARM,little endian" 4 "PC,ARM,big endian" 5 "PC,PowerPC(32bit)" 6 "PC,PowerPC(64bit)" 7 "PC,SPARC(32bit)" \
			8 "PC,SPARC(64bit)" 9 "PC,MIPS,little endian" 10 "PC,MIPS,big endian"  \
			--and-widget --no-shadow --ok-label "Boot" --output-separator "|" --form "Linux Direct Boot" 18 50 30 \
			"Machine Name:" 2 2 "" 3 2 30 50 "Path to Kernel Image:" 5 2 "" 6 2 30 50 "Path to Initial Ram Disk:" 8 2 "" 9 2 30 50 \
			"Kernel Commad Line:" 11 2 "" 12 2 30 50 --output-fd 4 4>${TEMP_FOLDER}/.direct_boot
			
			let test_cancel=$?
			
			
	[ -f ${TEMP_FOLDER}/.direct_boot ] && {
		
		[ $test_cancel -eq 0 ] && {
		
			set `cat ${TEMP_FOLDER}/.direct_boot`
		
			source ${QBOX_DIR}/bash_s/qemu-ph-box.sh %ARCHITECTURE% $1
			#QEMU=`cat ${TEMP_FOLDER}/.arch`
		
			VM_NAME=`echo $2 | gawk -F "|" '{print $1}'`
			KERNEL=`echo $2 | gawk -F "|" '{print $2}'` && KERNEL="-kernel ${KERNEL}"
			INITRD=`echo $2 | gawk -F "|" '{print $3}'` && INITRD="-initrd ${INITRD}"
			KERNEL_CMD=`echo $2 | gawk -F "|" '{print $4}'` && KERNEL_CMD="-append ${KERNEL_CMD}"
		
			[ "${VM_NAME}" = "" ] && VM_NAME=MY_VM$$ || [ "`unique_vm_name $VM_NAME`" != "" ] && VM_NAME=MY_VM$$
		
			HD_IMG=${VM_NAME}_linuz.img
			qvm_name=${VM_NAME}_linuz.qvm
			VM_NAME=`echo ${VM_NAME} | gawk '{print toupper($0)}'` && VM_NAME="-name $VM_NAME"
		
			test_cmd=`echo ${KERNEL_CMD} | gawk '{print $2}'` && [ "$test_cmd" = "" ] && KERNEL_CMD=""
		
			bash ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} % % % % % % % % \
			%${KERNEL} %${INITRD} % % % % %${KERNEL_CMD} % %
		
			bash ${QBOX_DIR}/bash_s/qemu-bootfile-reader.sh $qvm_name linuz
		
			test=0
			#rm -f ${TEMP_FOLDER}/.direct_boot
		} || test=0
		
	} || {
	
		dialog \
			--no-shadow --title "Input Error" --yesno "Error in input data\n\nDo you continue?" 18 50 
		
		[ $? -eq 0 ] && continue || test=0
		
	}
	
done

exit 0
