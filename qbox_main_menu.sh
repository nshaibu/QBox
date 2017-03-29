#!/bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: Main Menu
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

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include

if NOT_DEFINE ${CURSES_DIALOG_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
fi 

while : ; do 
	exec 3>&1
		value=$(${DIALOG} \
				--no-shadow --clear --cancel-label "Exit" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
				--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} 8 1 "Boot Created Virtual Machine" \
				2 "Create New Virtual Machine" 3 "Stop Running Virtual Machine" 4 "Delete Virtual Machine" 5 "Reconfigure Virtual Machine" \
				6 "Direct Linux Boot" 7 "QBox Remote Manager" 8 "Other Options" 2>&1 1>&3)
	
		let "test_return=$?"
	exec 3>&-
	
	case ${test_return} in 
		${DIALOG_OK}) 
			
			if [[ ${value} -eq 1 ]]; then
				:
			elif [[ ${value} -eq 2 ]]; then
				. ${LIB_DIR}/qbox_new_vm_menu.sh 
			elif [[ ${value} -eq 3 ]]; then
				:
			elif [[ ${value} -eq 4 ]]; then
				:
			elif [[ ${value} -eq 5 ]]; then
				:
			elif [[ ${value} -eq 6 ]]; then
				. ${LIB_DIR}/QBox/bash_s/direct_linux_boot.sh 
			elif [[ ${value} -eq 7 ]]; then
				:
			elif [[ ${value} -eq 8 ]]; then
				:
			fi
		;;
		${DIALOG_CANCEL}) break ;;
	esac
done 

