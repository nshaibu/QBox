#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
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

: ${LIB_DIR:=$HOME/my_script/QB/QBox/include_dir}

. ${LIB_DIR}/import '<init.h>'

_return_=""

function yes_no()
{
	read -n 1 resp
	case "$resp" in 
		[Nn]) echo 1;;
		*) echo 0 ;;
	esac
}

let INST_CON=0

function package_install_func() {
	
	local pkg_man="`type yum >/dev/null 2>&1 && which yum || type apt-get >/dev/null 2>&1 && which apt-get`"
	
	[[ ${INST_CON} -eq 0 ]] && {
		tput setaf 9
		echo -e "\n	NOTICE!!!\nQBox will now try to install [$1]\nIn case of [INSTALL-ERROR-LOOPS] press [CTRL+C] to exit\n"
		tput sgr0
		sleep 3 && INST_CON=10
		echo -e "Updating Cache..." && sudo ${pkg_man} update >/dev/null 2>&1
		[ $? -eq 0 ] && echo -e "[OK]" || echo -e "[ERROR]"
	}
	
	echo -e "Installing [$1]..." && sudo ${pkg_man} install $1 -y >/dev/null 2>&1
	[ $? -eq 0 ] && echo -e "[OK]" || { 
		echo -e "[ERROR]"
		package_install_func $1 
	}
}

function pkg_display_download(){
	path_error_display="`type zenity >/dev/null 2>&1 && which zenity || type dialog >/dev/null 2>&1 && which dialog || echo 1`"
	base_n="`[ "${path_error_display}" = "1" ] && echo 1 || basename $path_error_display`"
		
	case "-$base_n" in 
		-zenity) 
			${path_error_display} \
					--question --title="Package $1 Required"  --width=30 --height=20 --window-icon=question \
					--text="QBox required $1 to continue..\n Do you want to install it?" >/dev/null 2>&1
					
			if [ $? -eq 0 ]; then
				package_install_func $1
			else
				_return_="`which $1`"
			fi
		;;
		-dialog) 
			${path_error_display} \
					--no-shadow --title "Package $1 Required" --yesno "QBox required $1 to continue..\n Do you want to install it?" 18 50
			
			if [ $? -eq 0 ]; then
				clear
				package_install_func $1
			else
				_return_="`which $1`"
			fi 
		;;
		-1) 
			echo "Package $1 Required"
			echo -e "QBox required $1 to continue..\n Do you want to install it?[YES/no] "
			hld=$(yes_no)
			
			if [ $hld -eq 0 ]; then
				package_install_func $1
			else
				_return_="`which $1`"
			fi
		;;
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
								
	#move_center 4 25
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
					x=`expr $x + 1`
					echo -e "     $x. Installing package ..." && package_install_func $index
				done
		fi
		rm -f ${TEMP_FOLDER}/.CHECK_IFNOT_INSTALL 2>/dev/null
	fi
						
elif [[ $1 = "%CHECK_RUN%" ]]; then
								
	if type $2 >/dev/null 2>&1 ; then
		_return_="$(which $2)" 
	else
		pkg_display_download $2
	fi
	
	echo ${_return_}
fi

exit 0
