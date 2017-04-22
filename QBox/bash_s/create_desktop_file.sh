#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Create shortcuts
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

. ${LIB_DIR}/include

. ${LIB_DIR}/import '<init.h>'
. ${LIB_DIR}/import '<qdb_database.h>'

if NOT_DEFINE ${BASIC_UTILS_H}; then
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 
	
	
declare -a QDB_ARR=( $(init_database_qdb ${VMS_DB}) )
					
if [[ ${#QDB_ARR[*]} -eq 0 ]]; then 
	tput setaf 9
	printf "\n\t%s\n" "No Virtual Machine created yet..."
	tput sgr0
else 
	echo -e "\n\nselect a vm"
			
	for (( index=0; index<${#QDB_ARR[*]}; index++)); do
		vm_info=${QDB_ARR[$index]//\"/}
		echo "  $(( index+1 )).       $(return_first_field ${vm_info})"
	done 
						
	printf "\n%s" "Choose a VM to creat desktop shortcut[ENTER] "
	read name
						
	[ "${name}" != "" ] && {
		name=$(String_to_Upper ${name}) 
		let sizeof_arr=${#QDB_ARR[@]}
		QDB_ARR[$sizeof_arr]=${name}
		
		QDB_ARR=( $(search_val_qdb ${QDB_ARR[@]}) )
		let sizeof_arr=${#QDB_ARR[@]}
		vm_info_index=${QDB_ARR[$(( --sizeof_arr ))]}
		
		[ ${vm_info_index} -ne ${ARR_IS_EMPTY} ] && [ ${vm_info_index} -ne ${SRCH_VAL_NOT_IN_ARR} ] && { create_desktop_icon ${name}; }
	}
fi 
