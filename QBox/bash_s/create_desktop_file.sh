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
HD_IMG_DIR=$HOME/.img_qemubox ##contains harddisk images
QDB_DESKTOP=${HOME}/Desktop
QBOX_DIR=/usr/local/bin/QBox
QDB_FOLDER=${HD_IMG_DIR}/.qdb

function create_desktop_icon(){
	
	_filename="${QDB_DESKTOP}/`echo $1 | awk '{print tolower($0)}'`.desktop"
	touch ${_filename}
	
	echo -e "[Desktop Entry]\nTerminal=true">${_filename}
	echo -e "Encoding=UTF-8\nType=Application\nIcon=/usr/local/bin/QBox/icon/qbox_shortcut.png\nName=$1\nGenericName=Virtual Machine Manager">>${_filename}
	echo -e "Exec=sh -c '${QBOX_DIR}/QBox --startvm $1 ;$SHELL'\nComment=QBox for easy management of VMs locally or remotely">>${_filename}
	
	chmod 751 ${_filename}
}

${QBOX_DIR}/bash_s/qemu-sql-vms.sh l 2>/dev/null
		
echo
printf "%s" "Choose a VM to creat desktop shortcut[ENTER] "
read name

name=$(echo $name | awk '{print toupper($0)}') ##capitalise name

if [[ -n ${name} ]]; then
	search="^$name$"
	vm_file=$(gawk -F "|" -v var=$search '$1 ~ var {print $2}' ${QDB_FOLDER}/vms.qdb)
	
	if [[ "${vm_file}" != "" ]]; then
		create_desktop_icon ${name}
	fi 
fi 
