#!/bin/bash

# Copyright (C) 2016 Nafiu Shaibu.
#
#
# Qboxlogs is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your option) 
# any later version.

# QBoxlogs is distributed in the hopes that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

HD_IMG_DIR=$HOME/.img_qemubox
LOG_DIR=${HD_IMG_DIR}/logs_dir

function log_func(){
	echo -e "\n" 
	tput setaf 6
	echo -e "\t\t\t1. View logs"
	echo -e "\t\t\t2. Clear logs \n"
	tput sgr0
	echo -en "\t\t\tEnter Option "
	read -n 1 opt
}

log_func

case $opt in 
	1) less ${LOG_DIR}/qboxlog;;
	2) cat /dev/null > ${LOG_DIR}/qboxlog;;
esac

exit 0
