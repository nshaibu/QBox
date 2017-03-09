#!/bin/bash

# Copyright (C) 2016 Nafiu Shaibu.


HD_IMG_DIR=$HOME/.img_qemubox
QBOX_DIR=/usr/local/bin/QBox
PYTHON_LOC=${QBOX_DIR}/python3
DOC_ROOT=$QBOX_DIR/www
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
LOG_DIR=${HD_IMG_DIR}/logs_dir

IF_ADDR=`python ${PYTHON_LOC}/netiface_deter.py`
[ "${IF_ADDR}" = "" ] && IF_ADDR="localhost"

PHP_PARSER=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% php`
##logger_func sed ':a;N;$!ba;s/\n/ /g'
#1. :a create a label 'a'
#2. N append the next line to the pattern space
#3. $! if not the last line, ba branch (go to) label 'a'
#4. s substitute, /\n/ regex for new line, / / by a space, /g global match (as many times as it can)
function logger_logging(){
	if [ "`cat ${TEMP_FOLDER}/.error.tt 2>>/dev/null`" != "" ]; then 
		${QBOX_DIR}/bin/qemubox_logger "`sed ':a;N;$!ba;s/\n/ /g' ${TEMP_FOLDER}/.error.tt`" ${LOG_DIR}/qboxlog
	
		rm -f ${TEMP_FOLDER}/.error.tt
	fi
	return 0
}

function httpd_func(){
		echo
		if [ -f ${TEMP_FOLDER}/.svrpid ]; then
			tput setaf 9 
			echo -e "\n\nStart already start!!"
			tput sgr0
		else
			echo "Starting server..." && echo "QBox server started" > ${TEMP_FOLDER}/.error.tt && sleep 1
			logger_logging
			
			${PHP_PARSER} -S ${IF_ADDR}:4020 -t ${DOC_ROOT} 1>${TEMP_FOLDER}/.error.tt 2>&1 &
			echo "$!" > ${TEMP_FOLDER}/.svrpid
			logger_logging
			echo
			if [ "${IF_ADDR}" = "localhost" ];then
				path=$(which xdg-open || which gnome-open ) && $path "http://localhost:4020/www"
			else
				echo "Enter this url in your browser: http://${IF_ADDR}:4020"
			fi
		fi
}


	echo -e "\n" 
	echo -e "\t\t\t1. Start server"
	echo -e "\t\t\t2. Stop server \n"
	echo -en "\t\t\tEnter Option "
	read -n 1 opt

case $opt in 
	1) httpd_func ;;
	2) 
		if [ -f ${TEMP_FOLDER}/.svrpid ]; then 
			kill -9 `cat ${TEMP_FOLDER}/.svrpid` 2>/dev/null
			echo "QBox remote server stopped" > ${TEMP_FOLDER}/.error.tt
			logger_logging
			rm -f ${TEMP_FOLDER}/.svrpid
		else
			tput setaf 9 
			echo -e "\n\n\tRemote Server not started!!!"
			tput sgr0
		fi
	;;
esac

exit 0
