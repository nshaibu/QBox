#!bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Reconfigure already Created VM
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
declare -ar CATEGORIES=("Change_VM_Name" "Change_System_Settings" "Change_Audio_Settings" "Change_Display_Settings" "Change_Network_Settings" "Save")
HD_IMG_DIR=$HOME/.img_qemubox ##contains harddisk images
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox

ORIG_BOOTFILE=$1
COPY_BOOTFILE=${TEMP_FOLDER}/.UPDATE_FILE

function reconfigure_vm()
{
	
	if [[ $1 = "%GENERAL%" ]]; then
		:
	elif [[ $1 = "%SYSTEM%" ]]; then
		:
	elif [[ $1 = "%AUDIO%" ]]; then
		:
	elif [[ $1 = "%DISPLAY%" ]]; then
		:
	elif [[ $1 = "%NETWORK%" ]]; then
		:
	fi
}

PS3="Choose an Option: "

select options in ${CATEGORIES[@]}
do 
	
	case $options in 
		"Change_VM_Name") ;;
		"Change_System_Settings") ;;
		"Change Audio Settings") ;;
		"Change_Display_Settings") ;;
		"Change_Network_Settings") ;;
		"Save") break ;;
	esac
done
