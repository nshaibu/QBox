#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Generator boot file 
#-------------------------------------------------------------------------------------------
# This is free software; you can redistribute it and/or modify it
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

: ${LIB_DIR:=/usr/local/bin/QBox/include_dir}

. ${LIB_DIR}/include

. ${LIB_DIR}/import '<init.h>'
. ${LIB_DIR}/import '<interpreters.h>'

VM_BOOTFILE_NAME=""

##check and create boot folder
if ! [ -d ${BOOT_DIR} ];then
	mkdir ${BOOT_DIR}
fi

echo $* > ${TEMP_FOLDER}/.bootparam.tt

echo $(basename $1) > ${TEMP_FOLDER}/.bootfile.tt

##naming the bootfile with the name of harddisk image
VM_BOOTFILE_NAME=`${SED_INT} s/img/qvm/ ${TEMP_FOLDER}/.bootfile.tt`
rm -f ${TEMP_FOLDER}/.bootfile.tt 2>/dev/null

cut --delimiter=" " --complement -f1 ${TEMP_FOLDER}/.bootparam.tt | ${AWK_INT} -F% -f ${QBOX_DIR}/awk/qemu-bootfile-generator.awk > ${BOOT_DIR}/${VM_BOOTFILE_NAME}

rm -f ${TEMP_FOLDER}/.bootparam.tt 2>/dev/null


##This part of the code creates the database for the system
##check and creates qbox databse directory
if ! [ -d ${QDB_FOLDER} ];then
	mkdir ${QDB_FOLDER}
fi

##check if the vm is using tap interfaces.
[ -f ${TEMP_FOLDER}/.test_tap_exit.tt ] && TAP_DB="T" || TAP_DB="F"

##check and creates database file 
if ! [ -f ${QDB_FOLDER}/vms.qdb ];then
	touch ${QDB_FOLDER}/vms.qdb
fi 

##Vm_NAME\Bootfile name\(tap/notap[T/F])
echo "$4|${VM_BOOTFILE_NAME}|${TAP_DB}">>${QDB_FOLDER}/vms.qdb

