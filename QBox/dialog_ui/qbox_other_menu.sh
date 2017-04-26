#!/bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: Other options Menu
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

: ${LIB_DIR:=$HOME/my_script/QB/QBox/include_dir}

. ${LIB_DIR}/include

. ${LIB_DIR}/import '<init.h>'
. ${LIB_DIR}/import '<notify.h>'

if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${BASIC_UTILS_H}; then 
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 

while : ; do 
	#exit 0
	exec 3>&1
		value=$(${DIALOG} \
				--no-shadow --clear --cancel-label "Back" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
				--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} 4 1 "Information On Virtual Machines" \
				2 "Create Shortcut" 3 "QBox Logs" 2>&1 1>&3)
	
		let "test_return=$?"
	exec 3>&-
	
	case ${test_return} in 
		${DIALOG_OK}) 
			if [[ $value -eq 1 ]]; then 
				:
			elif [[ $value -eq 2 ]]; then 
				gen_str_=""
				
				declare -a QDB_ARR=( $(init_database_qdb ${VMS_DB}) ) ##initialize qdb
					
				if [[ ${#QDB_ARR[@]} -ne 0 ]]; then
					gen_str_=$(names_str_qdb ${QDB_ARR[@]}) #generate string to form qdb_arr 
				else 
					gen_str_="1 No_Virtual_Machine_created_yet..."
				fi 
				
				while : ; do 
					exec 3>&1
						value=$(${DIALOG} \
								--no-shadow --ok-label "Boot" --clear --cancel-label "Back" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
								--menu "\Zb\Z0QBox Shortcut\Zn\ZB\nExport Virtual machines shortcuts to Desktop." ${HEIGHT} ${WIDTH} \
								8 ${gen_str_} 2>&1 1>&3)
							
						let "test_return=$?"
					exec 3>&-
					
					case ${test_return} in 
						${DIALOG_OK}) 
							vm_info=${QDB_ARR[$(( value-1 ))]}
							vm_info=${vm_info//\"/}
							vm_info=${vm_info%%|*}
							
							[ -n $vm_info ] && { 
								create_desktop_icon ${vm_info} && {
									show_notification low ${QBOX_DIR}/icon/qbox_shortcut.png "$vm_info" \
									"$(get_string_by_name STRINGS_EXPORT_VM)"
								} 
							}
							break
						;;
						${DIALOG_CANCEL}) break ;;
					esac
				done 
			elif [[ $value -eq 3 ]]; then
				:
			fi 
			
		;;
		${DIALOG_CANCEL}) break ;;
	esac
	
done 
