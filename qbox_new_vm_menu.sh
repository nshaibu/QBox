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

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include

if NOT_DEFINE ${CURSES_DIALOG_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
fi 

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
				. ${LIB_DIR}/qbox_create_vm.sh 
			elif [[ $value -eq 2 ]]; then
				. ${LIB_DIR}/qbox_network_config.sh 
			elif [[ $value -eq 3 ]]; then
				. ${LIB_DIR}/qbox_boot_device.sh 
			fi 
		;;
		${DIALOG_BACK}) break ;;
	esac
done
