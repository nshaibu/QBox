#!/bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: Main Menu
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
. ${LIB_DIR}/import '<qdb_database.h>'
. ${LIB_DIR}/import '<boot_vm.h>'
. ${LIB_DIR}/import '<http_server.h>'

if NOT_DEFINE ${CURSES_DIALOG_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
fi 


while : ; do 
	exec 3>&1
		value=$(${DIALOG} \
				--no-shadow --clear --cancel-label "Exit" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
				--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} 8 1 "Boot Created Virtual Machine" \
				2 "Create New Virtual Machine" 3 "Stop Running Virtual Machine" 4 "Delete Virtual Machine" 5 "Reconfigure Virtual Machine" \
				6 "Direct Linux Boot" 7 "QBox Remote Manager" 8 "Other Options" 2>&1 1>&3)
	
		let "test_return=$?"
	exec 3>&-
	
	case ${test_return} in 
		${DIALOG_OK}) 
			
			if [[ ${value} -eq 1 ]]; then
				gen_str_=""
				
				declare -a QDB_ARR=( $(init_database_qdb ${VMS_DB}) ) ##initialize qdb
					
				if [[ ${#QDB_ARR[@]} -ne 0 ]]; then
					gen_str_=$(names_str_qdb ${QDB_ARR[@]}) #generate string to form qdb_arr 
				else 
					gen_str_="1 No_Virtual_Machine_created_yet..."
				fi 
				
				while true; do 
					exec 3>&1
						value=$(${DIALOG} \
								--no-shadow --clear --cancel-label "Back" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
								--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} \
								8 ${gen_str_} 2>&1 1>&3)
							
						let "test_return=$?"
					exec 3>&-
					
					case ${test_return} in 
						${DIALOG_OK}) 
							if [[ ${#QDB_ARR[@]} -ne 0 ]]; then
								bootfile=${QDB_ARR[$(( value-1 ))]}
								bootfile=${bootfile//\"/}
								
								boot_vm $(return_second_field ${bootfile}) $(return_first_field ${bootfile})
								if [[ $? -eq ${SUCCESS} ]]; then
									: #notify-send fullscn, keys shortcuts
								fi
							fi  
						;;
						${DIALOG_CANCEL}) break ;;
					esac
				done
			elif [[ ${value} -eq 2 ]]; then
				. ${LIB_DIR}/qbox_new_vm_menu.sh 
			elif [[ ${value} -eq 3 ]]; then
				gen_str_=""
				declare -a QDB_ARR=( $(init_database_qdb ${PID_DB}) ) ##initialize qdb
				
				if [[ ${#QDB_ARR[@]} -ne 0 ]]; then
					gen_str_=$(names_str_qdb ${QDB_ARR[@]})
				else 
					gen_str_="1 No_Virtual_Machine_is_running..."
				fi 
				
				while true; do 
					exec 3>&1
						value=$(${DIALOG} \
								--no-shadow --clear --cancel-label "Back" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
								--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} \
								7 ${gen_str_} 2>&1 1>&3)
							
						let "test_return=$?"
					exec 3>&-				
					
					case ${test_return} in 
						${DIALOG_OK}) 
							VM_clear_pid_qdb_eventhandler 
							
							[ ${#QDB_ARR[@]} -ne 0 ] && {
								pid=$(return_second_field ${QDB_ARR[$(( value-1 ))]})
								pid=${pid//\"/}
								kill -9 ${pid} 2>/dev/null
							} 
						;;
						${DIALOG_CANCEL}) break ;;
					esac
				done
			elif [[ ${value} -eq 4 ]]; then
				declare -a QDB_ARR=( $(init_database_qdb ${VMS_DB}) ) ##initialize qdb
				
				if [[ ${#QDB_ARR[*]} -ne 0 ]]; then
					gen_str_=$(names_str_qdb ${QDB_ARR[@]})
				else
					gen_str_="1 No_Virtual_Machine_created_yet..."
				fi 
				
				while true; do 
					exec 3>&1
						value=$(${DIALOG} \
								--no-shadow --clear --cancel-label "Back" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
								--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} \
								8 ${gen_str_} 2>&1 1>&3)
							
						let "test_return=$?"
					exec 3>&-				
					
					case ${test_return} in 
						${DIALOG_OK}) 
							if [[ ${#QDB_ARR[*]} -ne 0 ]]; then
								declare -i qdb_index=${#QDB_ARR[@]}
								declare -a QDB_COPY=( ${QDB_ARR[@]} )
								
								QDB_COPY[$(( qdb_index++ ))]="${value}"
								QDB_COPY[$(( qdb_index++ ))]=${QDB_ARR[$(( value-1 ))]}
								QDB_COPY[$(( qdb_index ))]=${VMS_DB}
								
								if delete_msg_qdb $(return_first_field ${QDB_ARR[$(( value-1 ))]}); then
									declare -a QDB_ARR=( $(delete_val_qdb ${QDB_COPY[@]}) )
									break
								else
									break
								fi 
							fi 
						;;
						${DIALOG_CANCEL}) break ;;
					esac
				done				
				
			elif [[ ${value} -eq 5 ]]; then
				:
			elif [[ ${value} -eq 6 ]]; then
				. ${LIB_DIR}/QBox/bash_s/direct_linux_boot.sh 
			elif [[ ${value} -eq 7 ]]; then
				while true; do 
					exec 3>&1
						value=$(${DIALOG} \
								--no-shadow --clear --cancel-label "Back" --colors --title "\Zb\Z0QBox VM Manager\Zn\ZB" \
								--menu "\Zb\Z0QBox Menu\Zn\ZB\nManage Virtual machine." ${HEIGHT} ${WIDTH} \
								3 1 "Start server" 2 "Stop server" 2>&1 1>&3)
							
						let "test_return=$?"
					exec 3>&-		
				
					case ${test_return} in 
						${DIALOG_OK}) 
							[ ${value} -eq 1 ] && {
								let "msg_str=" ", i=0, pid_t=-1"
								
								if server_is_not_running ; then
									tm_t=$(date +%T)
									pid_host_ip=$(httpd_start)
									
									pid_t=${pid_host_ip%%|*}
									host_ip_t=${pid_host_ip##*|}
								
									declare -a msg_arr=("[${pid_t}]using_host_ip:${host_ip_t}\n" "[${pid_t}]starting_httpd...\n" \
													"[${pid_t}]httpd_started_at_${tm_t}...\n" \
													"[${pid_t}]httpd_listening_on_port_4020\n" "[${pid_t}]trying_to_open_browser...\n" \
													"[${pid_t}]access:http://${host_ip_t}:4020" )
								fi 
									
								[ ${pid_t} -ne -1 ] && {
									while : ; do 
										msg_str+=${msg_arr[$i]//_/ }
						
										${DIALOG} \
											--no-shadow --colors --title "\Zb\Z0QBox server\Zn\ZB" --infobox "\n${msg_str}" $((HEIGHT-5)) $((WIDTH-6))
										sleep 2
										(( i++ ))
										[ $i -gt 5 ] && { echo ${pid_t}>${FILE_TEST_SERV_RUNNING}; msg_str=""; break; }
									done 
								} || {
									if server_is_not_running; then
										:
									else
										kill -9 $(cat ${FILE_TEST_SERV_RUNNING}) 2>/dev/null
									fi 
								}
								
							}
						;;
						${DIALOG_CANCEL}) break ;;
					esac
				done 
			elif [[ ${value} -eq 8 ]]; then
				:
			fi
		;;
		${DIALOG_CANCEL}) break ;;
	esac
done 

