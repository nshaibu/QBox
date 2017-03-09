#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Manage VM database
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

##global variables
HD_IMG_DIR=$HOME/.img_qemubox
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
QDB_FOLDER=${HD_IMG_DIR}/.qdb ##qbox database files location
LOG_DIR=${HD_IMG_DIR}/logs_dir
BOOT_DIR=${HD_IMG_DIR}/.qemuboot ## contain boot files
TAP_DIR=${HD_IMG_DIR}/.tap_dir ## contains tap interface script to be used by the vm

#Directory containing QBox
QBOX_DIR=/usr/local/bin/QBox

##check and creates qbox databse directory
if ! [ -d ${QDB_FOLDER} ];then
	mkdir ${QDB_FOLDER}
fi

##logger_func sed ':a;N;$!ba;s/\n/ /g'
#1. :a create a label 'a'
#2. N append the next line to the pattern space
#3. $! if not the last line, ba branch (go to) label 'a'
#4. s substitute, /\n/ regex for new line, / / by a space, /g global match (as many times as it can)
function logger_logging(){
	if [ "`cat ${TEMP_FOLDER}/.error.tt`" != "" ]; then 
		${QBOX_DIR}/bin/qemubox_logger "`sed ':a;N;$!ba;s/\n/ /g' ${TEMP_FOLDER}/.error.tt`" ${LOG_DIR}/qboxlog
	
		rm -f ${TEMP_FOLDER}/.error.tt
	fi
	return 0
}


if [ $1 = l ];then 
	if [ ! -s ${QDB_FOLDER}/vms.qdb ]; then
		echo -e "\n\nYou have not created any VM yet.."
	else
		echo -e "\n\nselect a vm"
		echo "$(cut --delimiter="|" -f1 ${QDB_FOLDER}/vms.qdb)">>tmp.tt 2>${TEMP_FOLDER}/.error.tt
		logger_logging
		
		x=0
		for i in $(cat tmp.tt)
		do 
			x=`expr $x + 1`
			echo "  $x.       $i"
		done
		rm -f tmp.tt
	fi 
elif [ $1 = s ];then
	searchvar=$2
		
		
	while true
	do 
		if [ "$searchvar" = "" ]; then
			echo "Choose a vm"
			read searchvar
			searchvar=$(echo $searchvar | awk '{print toupper($0)}') ##capitalise name
		fi 
		
		x=0
		for i in `cut --delimiter "|" -f1 ${QDB_FOLDER}/vms.qdb`
		do 
			if [ "$searchvar" = $i ];then
				x=`expr $x + 1`
				
				searchtap=$searchvar
				search="^$searchtap\$"
				
				set $(gawk -F "|" -v var=$search '$1 ~ var {print $2 " " $3}' ${QDB_FOLDER}/vms.qdb)
				
				## test whether tap interface was used for this vm 
				if [ "$2" = "T" ];then
					bash ${QBOX_DIR}/bash_s/qemuboxtap.sh $1 ##runs tap interface creation script
				else
					##bootfile echoed
					echo $1
				fi
				
				break 2
			fi
		done
	
		if [ $x -eq 0 ];then
			printf "%s\n" "     -> $searchvar was not found"
			break
		fi
	done
elif [ $1 = d ];then
	
	searchdel=$2
	
	while true; do 
		if [ "$searchdel" = "" ]; then
			echo "Enter vm name to delete"
			read searchdel
			searchdel=$(echo $searchdel | awk '{print toupper($0)}') ##capitalise name
		fi
		x=0
		for i in `cut --delimiter="|" -f1 ${QDB_FOLDER}/vms.qdb`
		do 
			if [ "$searchdel" = $i ];then
				x=`expr $x + 1`
				
				##This generate a regular expression which is in form ^ValueHere$ so that it can be used directly
				##in the gawk script for matching
				search="^$searchdel\$"
				bootfile=$(gawk -F "|" -v var=$search '$1 ~ var {print $0}' ${QDB_FOLDER}/vms.qdb | cut --delimiter="|" -f2)
				
				#delete harddisk img
				harddel=`cat "${BOOT_DIR}/$bootfile" | gawk -F "|" -v var=hdk '$1 ~ var {print $2}' | gawk '{print $2}'`
				rm -f $harddel 2>${TEMP_FOLDER}/.error.tt
				logger_logging
				
				rm -f "${BOOT_DIR}/$bootfile"
				break
			fi
		done
		
		if [ $x -eq 0 ];then
			printf "%s\n" "     -> $searchdel was not found"
			break
		else 
			
			search="^$searchdel\$"
			
			##This make sure that the name entered is deleted from the vms database
			echo $(gawk -F "|" -v var=$search '$1 !~ var {print $0 "\n"}' ${QDB_FOLDER}/vms.qdb) > ${TEMP_FOLDER}/vms.tt
			##replace black or space character with newline character
			sed -e 's/[[:blank:]]\+/\n/g' ${TEMP_FOLDER}/vms.tt 1> ${QDB_FOLDER}/vms.qdb
			
			rm -f ${TEMP_FOLDER}/vms.tt 2>${TEMP_FOLDER}/.error.tt
			logger_logging
			break
		fi
	done
	
fi

exit 0
