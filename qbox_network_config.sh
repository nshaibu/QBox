#!/bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: Configure Networks for VM, port redirection and shares
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

. ${LIB_DIR}/include '<true_test.h>'
. ${LIB_DIR}/include '<network.h>'

if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${ARCHITECTURE_H} || NOT_DEFINE ${BASIC_UTILS_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<architecture.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
fi 

if NOT_DEFINE ${HOST_IP_H} || NOT_DEFINE ${ERROR_H} ; then
	. ${LIB_DIR}/include '<host_ip.h>'
	. ${LIB_DIR}/include '<error.h>'
fi 

temp_file=/tmp/qbox.$$

trap "rm -f $temp_file" 0 1 2 5 15

declare -i HEIGHT=18
declare -i WIDTH=50

#keep values for global use 
global_MAC_FOR_USER_MODE=
global_MODEL_FOR_USER_MODE=
global_VLAN_FOR_USER_MODE=
global_USER_FOR_USER_MODE=
global_VLANUSER_FOR_USER_MODE=
global_MODEL=

printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

let "back_key_in_for_loop=${FAILURE}"
let "i=0"

while [ 1 ]; do 
	
	
	${DIALOG} \
			--no-shadow --clear --ok-label "Next" --cancel-label "Back" --colors --title "\Zb\Z0Network\Zn\ZB" \
			--menu "Choose the number of Network adapters to use" ${HEIGHT} ${WIDTH} 4 \
			1 "One Adapter" 2 "Two Adapters" \
			3 "Three Adapters" 4 "Four Adapters" 2>$temp_file
				
	if [[ $? -eq ${DIALOG_CANCEL} ]]; then
		break
	else 
		NUM_ADAPTER=`cat $temp_file`
		
		for ((j=0; j<${NUM_ADAPTER}; j++))
		do 
				
				#test the correctness of field values
				let "test_using_user_mode=${FAILURE}"
				let "back_key_in_for_loop=${FAILURE}"
				
			${DIALOG} \
				--no-shadow --extra-button --clear --colors --title "\Zb\Z0Network\Zn\ZB" --ok-label "Next" --extra-label "Back" \
				--menu "Select method to attach virtual \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 8 \
				1 "User mode network stack" 2 "Open tun/tap interface" 3 "Open listening Socket" \
				4 "Use already Opened tun/tap interface" 5 "Connect to listening Socket" \
				6 "Use already Opened TCP Socket" 7 "Create Shared VLAN via UDP multicast Socket" \
				8 "Use already Opened UDP multicast Socket" 2>$temp_file
				
				let "Test_Method=$?"
				let "TEST_ERROR_OCURRED=${SUCCESS}"
				
				if [[ ${Test_Method} -eq ${DIALOG_CANCEL} ]]; then
					break 2
				elif [[ ${Test_Method} -eq ${DIALOG_BACK} ]]; then
					back_key_in_for_loop=${SUCCESS}
					#continue
					break
				else
					ATTACH_METHOD=`cat $temp_file`
								
									
#							ADAPTER_TYPE		
				${DIALOG} \
					--no-shadow --clear --nook --nocancel --colors --title "\Zb\Z0Network\Zn\ZB" \
					--menu "Choose network adapter type \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 5 \
					1 "intel PRO/1000 MT Desktop 82540EM" 2 "Paravirtualized Network" \
					3 "PCnet-PCI II" 4 "Realtek RTL8139" 5 "NE2000 Compatible ISA" 2>$temp_file
					
					ADAPTER_TYPE=`cat $temp_file`
					case ${ADAPTER_TYPE} in 
						1) MODEL="pcnet" ;;
						2) MODEL="virtio" ;;
						3) MODEL="pcnet" ;;
						4) MODEL="rtl8139" ;;
						5) MODEL="ne2k_isa" ;;
					esac
											
					global_MODEL=${MODEL}
																		
					case ${ATTACH_METHOD} in 
						1) 
							test_using_user_mode=${SUCCESS}
							
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --default-button "Ok" --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" \
									--extra-label "Back" --form "User mode Network stack \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 12 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 17 -18 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3` #2>$temp_file
							
								RETURN_CODE=$?
							
								exec 3>&- ##close file descriptor
							
								case ${RETURN_CODE} in 
								
									$DIALOG_OK) 
										 
										MAC_ADDR=${values%%|*}
										TEMP_VLAN=${values#*|}
										VLAN_NUM=${TEMP_VLAN/|/}
									
										error_func_display $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN")								
										TEST_ERROR_OCURRED=$?
										
										[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ] && {
											
											#NETWORKi="-net nic"
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"
											
											USERi="-net_user"
											VLAN_USERi=",vlan=${VLAN_NUM}"
											
											#Enable access globally
											global_MAC_FOR_USER_MODE="${MACi}"
											global_MODEL_FOR_USER_MODE="${MODELi}"
											global_VLAN_FOR_USER_MODE="${VLANi}"
											global_USER_FOR_USER_MODE="${USERi}"
											global_VLANUSER_FOR_USER_MODE="${VLAN_USERi}"
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${REDIRECT0} " " \
											" " " " " " " " " " " " " " " " \
											" " " "
											
											#break 3
										}
									;;
									$DIALOG_BACK) break 2 ;;
								esac
							done 
						;;
						2) 
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Open tun/tap interface \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 12 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 16 -18 0 "TUN/TAP Script:" 7 1 " " 7 16 27 58 \
									"Interface Name:" 8 1 " " 8 16 27 58 2>&1 1>&3` # 2>$temp_file						
							
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
							
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_OK}) 
										#Extract values
										MAC_ADDR=`echo ${values} | cut -d "|" -f1`
										VLAN_NUM=`echo ${values} | cut -d "|" -f2`
										SCRIPT_PATH=`echo ${values} | cut -d "|" -f3`
									
										error_func_display $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN")							
										TEST_ERROR_OCURRED=$?
										
										[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ] && {
											
											NETWORKi="-net nic"
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEl}"
											
											TAPi="-net_tap"
											VLAN_TAPi=",vlan=${VLAN_NUM}"
											IFNAMEi=",ifname=${IF_NAME}"
											SCRIPTi=",script=${SCRIPT_PATH}"
													
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " ${TAPi} ${VLAN_TAPi} ${FD_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} ${MCASTi}
											
											#break 3
										}
									;;
								esac 	
							done						
						;;
						
						####################################################################
						#						Open listening Socket					   #
						####################################################################
						3) 
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Open listening Socket \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 18 15 "Port:" 2 32 "1" 2 37 6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 16 -18 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_OK}) 
									
										##Extracing ip address, port num, vlan num, 
										IP_ADDR=${values%%|*}
										PORT_NUM=`echo $values|cut -d "|" -f2`
										MAC_ADDR=`echo $values|cut -d "|" -f3`
										VLAN_NUM=`echo $values|cut -d "|" -f4`
										
										error_func_display $(err_str "IP_ADDR:${STRERROR[IP_ADDR]}:ip_func_pointer") $(err "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN") $(err_str "PORT_NUM:${STRERROR[PORT_NUM]}:is_valid_port_num")
										
										TEST_ERROR_OCURRED=$?
										
										[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"	
											
											SOCKETi="-net_socket"	
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"	
											LISTENi=",listen=${IP_ADDR}:${PORT_NUM}"	
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " " " " " " " " " " " ${SOCKETi} ${VLAN_SOCKETi} \
											${LISTENi} ${CONNECTi} ${FD_SOCKETi} ${MCASTi}
											#break 3							
										}
									;;
								esac 	
							done						
						;;
						
						####################################################################
						#			Use already Opened tun/tap interface	               #
						####################################################################						
						4) 
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Use already Opened tun/tap interface \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 15 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "0" 5 17 6 4 "TUN/TAP Script:" 7 1 " " 7 16 -27 58 \
									"Interface Name:" 8 1 " " 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
									${DIALOG_BACK}) break ;;
									${DIALOG_OK}) 
									
										MAC_ADDR=${values%%|*}
										VLAN_NUM=`echo $values|cut -d "|" -f2`
										FD_N=`echo $values|cut -d "|" -f3`
									
										error_func_display $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN") $(err_str "FD_N:${STRERROR[FD_N]}:is_valid_fd")
										TEST_ERROR_OCURRED=$?
										
										[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"
											
											TAPi="-net_tap"
											VLAN_TAPi=",vlan=${VLAN_NUM}"
											FD_TAPi=",fd=${FD_N}"
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " ${TAPi} ${VLAN_TAPi} ${FD_TAPi} \
											 ${IFNAMEi} ${SCRIPTi} " " " " " " "" " " " "
																					
											#break 3
										}
									;;
								esac 	
							done												
						;;
						
						####################################################################
						#			Connect to listening Socket  			               #
						####################################################################
						5) 
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Connect to listening Socket \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 18 15 "Port:" 2 32 "1" 2 37 6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 17 -6 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`			
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_OK}) 
									
										##Extracing ip address, port num, vlan num, 
										IP_ADDR=${values%%|*}
										PORT_NUM=`echo $values|cut -d "|" -f2`
										MAC_ADDR=`echo $values|cut -d "|" -f3`
										VLAN_NUM=`echo $values|cut -d "|" -f4`
									
										error_func_display $(err_str "IP_ADDR:${STRERROR[IP_ADDR]}:ip_func_pointer") $(err_str "PORT_NUM:${STRERROR[PORT_NUM]}:is_valid_port_num") $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN")
										
										TEST_ERROR_OCURRED=$?
										
										#setting values
										[ $TEST_ERROR_OCURRED -ne ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"
											
											SOCKETi="-net_socket"	
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											CONNECTi=",connect=${IP_ADDR}:${PORT_NUM}"
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " " " " " " " " " " " ${SOCKETi} ${VLAN_SOCKETi} \
											" " ${CONNECTi} ${FD_SOCKETi} ${MCASTi}
																						
											#break 3
										}
									;;
								esac 	
							done												
						;;
						
						####################################################################
						#			Use already Open listening TCP Socket	               #
						####################################################################						
						6) 
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Use already Open listening TCP Socket \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 15 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "0" 5 17 6 4 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_OK}) 
									
										MAC_ADDR=${values%%|*}
										VLAN_NUM=`echo $values|cut -d "|" -f2`
										FD_N=`echo $values|cut -d "|" -f3`
									
										error_func_display $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN") $(err_str "FD_N:${STRERROR[FD_N]}:is_valid_fd")
										
										TEST_ERROR_OCURRED=$?
										
										#setting values
										[ $TEST_ERROR_OCURRED -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"
											
											SOCKETi="-net_socket"
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											FD_SOCKETi=",fd=${FD_N}"
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " " " \
											" " " " " " " " ${SOCKETi} ${VLAN_SOCKETi} " " " " ${FD_SOCKETi} " "
																						
											#break 3
										}
									;;
								esac 	
							done												
						;;
						
						####################################################################
						#			Create Shared VLAN via UDP multicast Socket            #
						####################################################################						
						7) 
							exec 3>&1 ##create new file descriptor
							
							values=`${DIALOG} \
								--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
								--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
								--form "Create Shared VLAN via UDP multicast Socket \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
								"IP Address:" 2 1 "" 2 13 18 15 "Port:" 2 32 "1" 2 37 6 6 \
								"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
								"File descriptor:" 5 1 "" 5 16 -18 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
								"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
							RETURN_CODE=$?
							exec 3>&- ##close file descriptor
								
							case ${RETURN_CODE} in 
								
								${DIALOG_BACK}) break ;;
								${DIALOG_OK}) 
								
									##Extracing ip address, port num, vlan num, 
									IP_ADDR=${values%%|*}
									PORT_NUM=`echo $values|cut -d "|" -f2`
									MAC_ADDR=`echo $values|cut -d "|" -f3`
									VLAN_NUM=`echo $values|cut -d "|" -f4`
									
									error_func_display $(err_str "IP_ADDR:${STRERROR[IP_ADDR]}:ip_func_pointer") $(err_str "PORT_NUM:${STRERROR[PORT_NUM]}:is_valid_port_num") $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN")
									TEST_ERROR_OCURRED=$?
									
									#setting values
									[ $TEST_ERROR_OCURRED -ne ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"
											
											SOCKETi="-net_socket"
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											MCASTi=",mcast=${IP_ADDR}:${PORT_NUM}"
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " " " \
											" " " " " " " " ${SOCKETi} ${VLAN_SOCKETi} " " " " \
											" " ${MCASTi}
																						
											#break 3
									}									
								;;
								
							esac 													
						;;
						
						
						8) 
							while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --nocancel --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Use already Opened UDP multicast Socket \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 15 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "0" 5 17 6 4 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_OK}) 
									
										MAC_ADDR=${values%%|*}
										VLAN_NUM=`echo $values|cut -d "|" -f2`
										FD_N=`echo $values|cut -d "|" -f3`
									
										error_func_display $(err_str "MAC_ADDR:${STRERROR[MAC_ADDR]}:is_valid_macaddr") $(err_str "VLAN_NUM:${STRERROR[VLAN_NUM]}:is_valid_VLAN") $(err_str "FD_N:${STRERROR[FD_N]}:is_valid_fd")
										
										TEST_ERROR_OCURRED=$?
										
										#setting values
										[ $TEST_ERROR_OCURRED -ne ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${global_MODEL}"
											
											SOCKETi="-net_socket"
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											FD_SOCKETi=",fd=${FD_N}"
											
											set_parameters ${j} ${VLANi} ${MACi} ${MODELi} " " " " " " " " \
											" " " " " " " " ${SOCKETi} ${VLAN_SOCKETi} " " " " \
											${FD_SOCKETi} " "
																						
											#break 3
										}										
									;;
								esac 	
							
							done												
						;;
					
					esac 
						
				#fi 
				
				let "TEST_ERROR_OCURRED=${SUCCESS}"
			
				[[ ${test_using_user_mode} -eq ${SUCCESS} ]] && {	
					
					test_using_user_mode=${FAILURE}
					
					exec 3>&1
					
					value=`${DIALOG} \
						--no-shadow --no-tags --output-separator "|" --clear --colors --title "\Zb\Z0Port Redirection And SMB\Zn\ZB" \
						--checklist "\Zb\Z0SMB\Zn\ZB allows SMB-aware Operating Systems to access host files in a specified directory. A built-in samba server is activated for this purpose.\n\Zb\Z0Port redirecting\Zn\ZB incoming TCP or UDP connections to the host port to the guest IP address on a specified guest port .It allows telneting into a virtual machine.\n\nPress the \Zb\Z0space-key\Zn\ZB to make a choice" ${HEIGHT} ${WIDTH} 2 1 "Enable Samba Share" off 2 "Enable VM Port Redirection" off 2>&1 1>&3`
						
					let "test_return=$?"
					exec 3>&-
					
					tmp_value=${value#*|}
					declare -i value_smb=${tmp_value%%|*}
					declare -i value_redir=${value##*|}
					
						case ${test_return} in 
							${DIALOG_OK}) 
								[[ "$value_smb" = "1" ]] && {
								#Wed 08 Feb 2017 10:27:55 PM GMT 
									if ! [ -d ${HOME}/qboxShare ]; then 
										mkdir ${HOME}/qboxShare
									fi 
									
									SMB_SERVER=",smb=${HOME}/qboxShare"
									
									${DIALOG} \
										--no-shadow --clear --colors --title "\Zb\Z0SMB Info\Zn\ZB" \
										--msgbox "Note that a SAMBA server must be installed on the host OS. QEMU was tested successfully with smbd versions from Red Hat 9,Fedora Core 3 and OpenSUSE 11.x.\n\nThe host directory \n     \Zb\Z0[${HOME}/qboxShare]\Zn\ZB\n can be accessed in \n     \Zb\Z0[/smbserver/qemu]\Zn\ZB\n in the guest OS." ${HEIGHT} ${WIDTH}
								
								}
								
								if [[ "$value_redir" = "2" ]]; then
								exec 3>&1
								
								value=`${DIALOG} \
									--no-shadow --clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB" \
									--menu "Choose a Protocol \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 2 1 "TCP-Transmission Control Protocol" \
									2 "UDP-User Datagram Protocol" 2>&1 1>&3`
									
								exec 3>&-
								
								case ${value} in 
									1) 
										while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
											exec 3>&1
													
											values=`${DIALOG} \
												--no-shadow --output-separator "|" --trim --clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB"\
												--cancel-label "Back" --form "Port Redirection \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
												"On Host Port:" 2 2 "1" 2 15 6 5 "To Guest IP:" 4 2 "" 4 14 18 15 \
												"For Guest Port:" 6 2 "1" 6 17 6 5 2>&1 1>&3`
													
											let "test_return=$?"
											exec 3>&-
												
											case ${test_return} in 
												${DIALOG_CANCEL}) break ;;
												${DIALOG_OK}) 
														
													HOST_PORT_NUM=${values%%|*}
													GUEST_IP_ADDR=`echo $values|cut -d "|" -f2`
													GUEST_PORT_NUM=`echo $values|cut -d "|" -f3`
													
													IP_ADDR=${GUEST_IP_ADDR}
													
													error_func_display $(err_str "IP_ADDR:${STRERROR[IP_ADDR]}:ip_func_pointer") $(err_str "HOST_PORT_NUM:${STRERROR[HOST_PORT_NUM]}:is_valid_port_num") $(err_str "GUEST_PORT_NUM:${STRERROR[GUEST_PORT_NUM]}:is_valid_port_num")
													
													TEST_ERROR_OCURRED=$?
													
													#set parameters
													HOSTFWD=",hostfwd=tcp:${HOST_IP}:${HOST_PORT_NUM}-${GUEST_IP_ADDR}:${GUEST_PORT_NUM}"
													[[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ]] && {
														
														set_parameters ${j} ${global_VLAN_FOR_USER_MODE} ${global_MAC_FOR_USER_MODE} \
														${global_MODEL_FOR_USER_MODE} ${global_USER_FOR_USER_MODE} ${global_VLANUSER_FOR_USER_MODE} \
														${HOSTFWD}  "" "" "" "" "" "" "" "" "" "" ""
													}
												;;
											esac
											
										done 
									;;
									2) 
										
										while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
											exec 3>&1
													
											values=`${DIALOG} \
												--no-shadow --output-separator "|" --trim --clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB"\
												--cancel-label "Back" --form "Port Redirection \Zb[adapter ${j}]\ZB" ${HEIGHT} ${WIDTH} 10 \
												"On Host Port:" 2 2 "1" 2 15 6 4 "To Guest IP:" 4 2 "" 4 14 18 15 \
												"For Guest Port:" 6 2 "1" 6 17 6 4 2>&1 1>&3`
												
											let "test_return=$?"
											exec 3>&-
													
											case ${test_return} in 
												${DIALOG_CANCEL}) break ;;
												${DIALOG_OK}) 
														
													HOST_PORT_NUM=${values%%|*}
													GUEST_IP_ADDR=`echo $values|cut -d "|" -f2`
													GUEST_PORT_NUM=`echo $values|cut -d "|" -f3`
													
													IP_ADDR=${GUEST_IP_ADDR}
													
													error_func_display $(err_str "IP_ADDR:${STRERROR[IP_ADDR]}:ip_func_pointer") $(err_str "HOST_PORT_NUM:${STRERROR[HOST_PORT_NUM]}:is_valid_port_num") $(err_str "GUEST_PORT_NUM:${STRERROR[GUEST_PORT_NUM]}:is_valid_port_num")
													
													TEST_ERROR_OCURRED=$?
													
													#set parameters
													HOSTFWD=",hostfwd=udp:${HOST_IP}:${HOST_PORT_NUM}-${GUEST_IP_ADDR}:${GUEST_PORT_NUM}"
													[[ ${TEST_ERROR_OCURRED} -ne ${SUCCESS} ]] && {
														
														set_parameters ${j} ${global_VLAN_FOR_USER_MODE} ${global_MAC_FOR_USER_MODE} \
														${global_MODEL_FOR_USER_MODE} ${global_USER_FOR_USER_MODE} ${global_VLANUSER_FOR_USER_MODE} \
														${HOSTFWD}  "" "" "" "" "" "" "" "" "" "" ""
														
													}								
												;;
											esac
													
										done 			
									;;
								esac
							fi 
							;;
							${DIALOG_CANCEL}) [[ ${NUM_ADAPTER} -eq ${j} ]] && break 2 ;;
						esac
				}
				
				fi 		
		done 
				
	fi 
	
	[ ${back_key_in_for_loop} -eq ${FAILURE} ] && break
	
done			

