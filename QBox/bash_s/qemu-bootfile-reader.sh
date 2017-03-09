#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Boot VM from generated bootfile 
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

#global variables
HD_IMG_DIR=$HOME/.img_qemubox ##contains harddisk images
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
BOOT_DIR=${HD_IMG_DIR}/.qemuboot ##contains bootfiles
PID_FILE=${TEMP_FOLDER}/.pid
QDB_FOLDER=${HD_IMG_DIR}/.qdb

##check and create boot folder
if ! [ -d ${BOOT_DIR} ];then
	mkdir ${BOOT_DIR}
fi


##Replace newline char with space
BOOT_TMP=`find ${BOOT_DIR} -depth -type f -a -name $1 -exec cut -d "|" -f 2 {} \; 2>/dev/null | sed ':a;N;$!ba;s/\n/ /g'` 
	
##Replace multiple space char with a space char
BOOT_TMP0=`echo ${BOOT_TMP} | tr -s " "`

##Replace " ," with ","
BOOT=${BOOT_TMP0// ,/,} 

##Boot
${BOOT} 2>/dev/null & 
pid_vm=$!
	
echo "$2|$pid_vm">>${QDB_FOLDER}/pid.qdb
exit 0
