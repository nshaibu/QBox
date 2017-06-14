#!/bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: Check and Install Packages Required by QBox
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

trap 'exit 0' INT

: ${LIB_DIR:=/usr/local/bin/QBox/include_dir}

. ${LIB_DIR}/import '<init.h>'

if NOT_DEFINE ${LOGGS_H} || NOT_DEFINE ${BASIC_UTILS_H}; then
	. ${LIB_DIR}/include '<loggs.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 
_return_=""

function yes_no() {
	read -n 1 resp
	case "$resp" in 
		[Nn]) echo 1;;
		*) echo 0 ;;
	esac
}

function pkg_installed(){
	local _return=1
	#set return to zero if package not install
	case "$1" in 
		qemu-img) type $1 >/dev/null 2>&1 || { local _return=0; echo "qemu" > ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL; } ;;
		brctl) type $1 >/dev/null 2>&1 || { local _return=0; echo "bridge-utils" >> ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL; } ;;
		tunctl) type $1 >/dev/null 2>&1 || { local _return=0; echo "uml-utilities" >> ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL; } ;;
	esac
	
	echo $_return
}

function show_fail(){
	tput setaf 9
	printf "\U274C ${1}"
	tput sgr0
}

function show_pass(){
	tput setaf 4
	printf "\U2713 ${1}"
	tput sgr0
}

function show_if(){
	if [ $1 -eq 1 ];then
		show_pass $2
	else
		show_fail $2
	fi
}


if [[ $1 = "%CHECK_START%" ]]; then
##qemu(qemu-img),bridge-utils(brctl),uml-utilities(tunctl),check mark(U+2713), cross mark(U+274C)
	echo -e "\tQemu-utilities		$(show_if $(pkg_installed qemu-img))" && sleep 1
	echo -e "\tBridge-utilities	$(show_if $(pkg_installed brctl))" && sleep 1
	echo -e "\tUml-utilities		$(show_if $(pkg_installed tunctl))" && sleep 1
									
	let "x=0"
	if [[ -f ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL ]]; then
		
		printf "%s " "Do you want to install the packages[Y/n]?"
		read -n 1 resp
		echo
		if [[ "$resp" = "y" ]]; then
				for index in $(cat ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL)
				do 
					INST_CON=0
					x=`expr $x + 1`
					echo -e "     $x. Installing package ..." && package_install_func $index
				done
		fi
		rm -f ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL 2>/dev/null
	fi
						
elif [[ $1 = "%CHECK_RUN%" ]]; then
								
	if type $2 >/dev/null 2>&1 ; then
		_return_="$(which $2)" 
	fi
	
	echo ${_return_}
fi
