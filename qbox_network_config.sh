#!/bin/bash

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include '<network.h>'
. ${LIB_DIR}/include '<true_test.h>'

if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${ARCHITECTURE_H} ; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<architecture.h>'
fi 

if NOT_DEFINE ${HOST_IP_H} ; then
	. ${LIB_DIR}/include '<host_ip.h>'
fi 

temp_file=/tmp/qbox.$$

trap "rm -f $temp_file" 0 1 2 5 15

declare -i HEIGHT=18
declare -i WIDTH=50

#keep values for global use 
global_MAC_FOR_USER_MODE=
global_MODEL_FOR_USER_MODE=
global_VLAN_FOR_USER_MODE=
		
		
##Test whether input is char 
function isdigit(){
	if [ -z "$1" ]; then
		return 	$FAILURE
	fi 
	
	case "$1" in 
		[[:digit:]]|[[:digit:]]*) return $SUCCESS ;;
		*)	return $FAILURE ;;
	esac
}

##Verify IP address format
function is_IP_Valid(){
	
	local _return=${FAILURE}
	
	if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
		OLDIFS=${IFS}
		IFS="."
		declare -a IP=($1)
		IFS=${OLDIFS}
		[[ ${IP[0]} -le 255 ]] && [[ ${IP[1]} -le 255 ]] && [[ ${IP[2]} -le 255 ]] && [[ ${IP[3]} -le 255 ]] && {
			_return=${SUCCESS}
		}
	fi 
	
	return $_return
}

printf -v MACADDR "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

		
		
function error_display(){ 
	
	local _return=${SUCCESS}
	
	[ $1 -eq ${SUCCESS} ] && [ $2 -eq ${SUCCESS} ] && [ $3 -eq ${SUCCESS} ] && [ $4 -eq ${SUCCESS} ] && [ $5 -eq ${SUCCESS} ] || {
	
			if [[ $1 -eq ${FAILURE} ]]; then
				mac_err_str="|* Mac Address not in right the format [xx:xx:xx:xx:xx:xx]"
				_return=${FAILURE}
			elif [[ $2 -eq ${FAILURE} ]]; then
				vlan_err_str="|* Vlan number should be within this range [0-1000]"
				_return=${FAILURE}
			elif [[ $3 -eq ${FAILURE} ]]; then
				ip_err_str="|* IP Address not in right the format [xxx.xxx.xxx.xxx]"
				_return=${FAILURE}
			elif [[ $4 -eq ${FAILURE} ]]; then
				fd_err_str="|* File descriptor should be within this range [0-1000]"
				_return=${FAILURE}
			elif [[ $5 -eq ${FAILURE} ]]; then
				port_err_str="|* Port Number should be with this range [1-65535]"
				_return=${FAILURE}
			fi 
	
			error_str="${mac_err_str} ${vlan_err_str} ${ip_err_str} ${fd_err_str} ${port_err_str}"
			error_str=`echo ${error_str} | tr -s " "`
			str_error=${error_str//|/\\n}
	
			${DIALOG} \
				--colors --title "\Zb\Z1Input Error\Zn\ZB" --msgbox "${str_error}" $((HEIGHT-7)) $((WIDTH-20))
	}
	
	return ${_return}
}


function set_parameters(){
	if [[ $1 -eq 0 ]]; then
		
		NETWORK0="-net nic"
		VLAN0=$2
		MAC0=$3
		MODEL0=$4
		
		USER0=$5
		VLAN_USER0=$6	
		
		TAP0=$7
		VLAN_TAP0=$8
		IFNAME0=$9
		SCRIPT0=${10}
		FD_TAP0=${11}
		
		SOCKET0=${12}	
		VLAN_SOCKET0=${13}	
		LISTEN0=${14}
		CONNECT0=${15}	
		FD_SOCKET0=${16} 
		MCAST0=${17}
		
	elif [[ $1 -eq 1 ]]; then
		
		NETWORK1="-net nic"
		VLAN1=$2
		MAC1=$3
		MODEL1=$4
		
		USER1=$5
		VLAN_USER1=$6	
		
		TAP1=$7
		VLAN_TAP1=$8
		IFNAME1=$9
		SCRIPT1=${10}
		FD_TAP1=${11}
		
		SOCKET1=${12}	
		VLAN_SOCKET1=${13}	
		LISTEN1=${14}
		CONNECT1=${15}	
		FD_SOCKET1=${16} 
		MCAST1=${17}
	elif [[ $1 -eq 2 ]]; then
		
		NETWORK2="-net nic"
		VLAN2=$2
		MAC2=$3
		MODEL2=$4
		
		USER2=$5
		VLAN_USER2=$6	
		
		TAP2=$7
		VLAN_TAP2=$8
		IFNAME2=$9
		SCRIPT2=${10}
		FD_TAP2=${11}
		
		SOCKET2=${12}	
		VLAN_SOCKET2=${13}	
		LISTEN2=${14}
		CONNECT2=${15}	
		FD_SOCKET2=${16}
		MCAST2=${17}	
	
	elif [[ $1 -eq 3 ]]; then
		NETWORK3="-net nic"
		VLAN3=$2
		MAC3=$3
		MODEL3=$4
		
		USER3=$5
		VLAN_USER3=$6	
		
		TAP3=$7
		VLAN_TAP3=$8
		IFNAME3=$9
		SCRIPT3=${10}
		FD_TAP3=${11}
		
		SOCKET3=${12}	
		VLAN_SOCKET3=${13}	
		LISTEN3=${14}
		CONNECT3=${15}	
		FD_SOCKET3=${16} 
		MCAST3=${17}	
	fi	
}

let "back_key_in_for_loop=${FAILURE}"

while [ 1 ]; do 
	
	
	${DIALOG} \
			--no-shadow --clear --ok-label "Next" --colors --title "\Zb\Z0Network\Zn\ZB" \
			--menu "Choose the number of Network adapters to use" ${HEIGHT} ${WIDTH} 4 \
			1 "One Adapter" 2 "Two Adapters" \
			3 "Three Adapters" 4 "Four Adapters" 2>$temp_file
				
	if [[ $? -eq ${DIALOG_CANCEL} ]]; then
		break
	else 
		NUM_ADAPTER=`cat $temp_file`
		
		for ((i=0; i<${NUM_ADAPTER}; i++))
		do 
				#test the correctness of field values
				let "test_mac=${FAILURE}"
				let "test_vlan=${FAILURE}"
				let "test_ip=${FAILURE}"
				let "test_fd=${FAILURE}"
				let "test_port=${FAILURE}"
				let "test_using_user_mode=${FAILURE}"
				let "back_key_in_for_loop=${FAILURE}"
				
			${DIALOG} \
				--no-shadow --extra-button --clear --colors --title "\Zb\Z0Network\Zn\ZB" --ok-label "Next" --extra-label "Back" \
				--menu "Select method to attach virtual \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 8 \
				1 "User mode network stack" 2 "Open tun/tap interface" 3 "Open listening Socket" \
				4 "Use already Opened tun/tap interface" 5 "Connect to listening Socket" \
				6 "Use already Opened TCP Socket" 7 "Create Shared VLAN via UDP multicast Socket" \
				8 "Use already Opened UDP multicast Socket" 2>$temp_file
				
				let "Test_Method=$?"
				let "TEST_ERROR_FUNC_RETN=${FAILURE}"
				
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
					--menu "Choose network adapter type \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 5 \
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
											
																		
					case ${ATTACH_METHOD} in 
						1) 
							test_using_user_mode=${SUCCESS}
							
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --default-button "Ok" --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" \
									--extra-label "Back" --form "User mode Network stack \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
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
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
									
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi
										
										error_display ${test_mac} ${test_vlan} ${SUCCESS} ${SUCCESS} ${SUCCESS}
										TEST_ERROR_FUNC_RETN=$?
										
										[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ] && {
											
											#NETWORKi="-net nic"
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEL}"
											USERi="-net user"
											VLAN_USERi=",vlan=${VLAN_NUM}"
											
											#Enable access globally
											global_MAC_FOR_USER_MODE=${MACi}
											global_MODEL_FOR_USER_MODE=${MODELi}
											global_VLAN_FOR_USER_MODE=${VLANi}
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} ${IFNAMEi} \
											${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} ${MCASTi}
											
											#break 3
										}
									;;
									$DIALOG_BACK) 
										#back_key_in_for_loop=${SUCCESS}
										break 2
									;;
									$DIALOG_CANCEL) break 3 ;;	
								
								esac
							done 
						;;
						2) 
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Open tun/tap interface \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 12 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 16 -18 0 "TUN/TAP Script:" 7 1 "" 7 16 27 58 \
									"Interface Name:" 8 1 "" 8 16 27 58 2>&1 1>&3` # 2>$temp_file						
							
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
							
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_CANCEL}) break 2 ;;
									${DIALOG_OK}) 
										#Extract values
										MAC_ADDR=`echo ${values} | cut -d "|" -f1`
										VLAN_NUM=`echo ${values} | cut -d "|" -f2`
										SCRIPT_PATH=`echo ${values} | cut -d "|" -f3`
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
									
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi
									
										error_display ${test_mac} ${test_vlan} ${SUCCESS} ${SUCCESS} ${SUCCESS}
										TEST_ERROR_FUNC_RETN=$?
										
										[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ] && {
											
											NETWORKi="-net nic"
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEl}"
											TAPi="-net tap"
											VLAN_TAPi=",vlan=${VLAN_NUM}"
											IFNAMEi=",ifname=${IF_NAME}"
											SCRIPTi=",script=${SCRIPT_PATH}"
													
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}											
											
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
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Open listening Socket \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 18 15 "Port:" 2 32 "1" 2 37 6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 16 -18 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_CANCEL}) break 2 ;;
									${DIALOG_OK}) 
									
										##Extracing ip address, port num, vlan num, 
										IP_ADDR=${values%%|*}
										PORT_NUM=`echo $values|cut -d "|" -f2`
										MAC_ADDR=`echo $values|cut -d "|" -f3`
										VLAN_NUM=`echo $values|cut -d "|" -f4`
										
										if [ -z ${GUEST_IP_ADDR} ] || is_IP_Valid ${GUEST_IP_ADDR}; then
											test_ip=${SUCCESS}
										fi 		
													
										##verify port number
										if isdigit ${PORT_NUM} && [ ${PORT_NUM} -ge 1 ] && [ ${PORT_NUM} -le 65535 ]; then
											test_port=${SUCCESS}
										fi 
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
									
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi	
									
										error_display ${test_mac} ${test_vlan} ${test_ip} ${SUCCESS} ${test_port}
										TEST_ERROR_FUNC_RETN=$?
										
										[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEL}"	
											SOCKETi="-net socket"	
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"	
											LISTENi=",listen=${IP_ADDR}:${PORT_NUM}"	
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}												
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
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Use already Opened tun/tap interface \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 15 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "0" 5 17 6 4 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								[[ ${RETURN_CODE} -eq ${DIALOG_BACK} ]] && { break; }
								case ${RETURN_CODE} in 
									${DIALOG_CANCEL}) break 2 ;;
									${DIALOG_OK}) 
									
										MAC_ADDR=${values%%|*}
										VLAN_NUM=`echo $values|cut -d "|" -f2`
										FD_N=`echo $values|cut -d "|" -f3`
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
									
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi	
									
										if isdigit ${FD_N} && [ ${FD_N} -ge 0 ] && [ ${FD_N} -le 1000 ]; then
											test_fd=${SUCCESS}
										fi	
									
										error_display ${test_mac} ${test_vlan} ${SUCCESS} ${test_fd} ${SUCCESS}
										TEST_ERROR_FUNC_RETN=$?
										
										[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEL}"
											TAPi="-net tap"
											VLAN_TAPi=",vlan=${MAC_ADDR}"
											FD_TAPi=",fd=${FD_N}"
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}		
																					
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
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Connect to listening Socket \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 18 15 "Port:" 2 32 "1" 2 37 6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 17 -6 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`			
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_CANCEL}) break 2 ;;
									${DIALOG_OK}) 
									
										##Extracing ip address, port num, vlan num, 
										IP_ADDR=${values%%|*}
										PORT_NUM=`echo $values|cut -d "|" -f2`
										MAC_ADDR=`echo $values|cut -d "|" -f3`
										VLAN_NUM=`echo $values|cut -d "|" -f4`
									
										[ -z ${IP_ADDR} ] && test_ip=${SUCCESS}
										if [ -n ${IP_ADDR} ] && is_IP_Valid ${IP_ADDR}; then
											test_ip=${SUCCESS}
										fi 
									
										##verify port number
										if isdigit ${PORT_NUM} && [ ${PORT_NUM} -ge 1 ] && [ ${PORT_NUM} -le 65535 ]; then
											test_port=${SUCCESS}
										fi 
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
									
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi												
									
										error_display ${test_mac} ${test_vlan} ${test_ip} ${SUCCESS} ${test_port}
										TEST_ERROR_FUNC_RETN=$?
										
										#setting values
										[ $TEST_ERROR_FUNC_RETN -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODEi=",model=${MODEL}"
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											CONNECTi=",connect=${IP_ADDR}:${PORT_NUM}"
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}	
																						
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
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Use already Open listening TCP Socket \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 15 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "0" 5 17 6 4 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_CANCEL}) break 2 ;;
									${DIALOG_OK}) 
									
										MAC_ADDR=${values%%|*}
										VLAN_NUM=`echo $values|cut -d "|" -f2`
										FD_N=`echo $values|cut -d "|" -f3`
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
									
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi	
									
										if isdigit ${FD_N} && [ ${FD_N} -ge 0 ] && [ ${FD_N} -le 1000 ]; then
											test_fd=${SUCCESS}
										fi 
									
										error_display ${test_mac} ${test_vlan} ${SUCCESS} ${test_fd} ${SUCCESS}
										TEST_ERROR_FUNC_RETN=$?
										
										#setting values
										[ $TEST_ERROR_FUNC_RETN -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEL}"
											SOCKETi="-net socket"
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											FD_SOCKETi=",fd=${FD_N}"
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}	
																						
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
								--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
								--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
								--form "Create Shared VLAN via UDP multicast Socket \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
								"IP Address:" 2 1 "" 2 13 18 15 "Port:" 2 32 "0" 2 37 6 6 \
								"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
								"File descriptor:" 5 1 "" 5 16 -18 0 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
								"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
							RETURN_CODE=$?
							exec 3>&- ##close file descriptor
								
							case ${RETURN_CODE} in 
								
								${DIALOG_BACK}) break ;;
								${DIALOG_CANCEL}) break 2 ;;
								${DIALOG_OK}) 
								
									##Extracing ip address, port num, vlan num, 
									IP_ADDR=${values%%|*}
									PORT_NUM=`echo $values|cut -d "|" -f2`
									MAC_ADDR=`echo $values|cut -d "|" -f3`
									VLAN_NUM=`echo $values|cut -d "|" -f4`
									
									[ -z ${IP_ADDR} ] && test_ip=${SUCCESS}
									if [ -n ${IP_ADDR} ] && is_IP_Valid ${IP_ADDR}; then
										test_ip=${SUCCESS}
									fi 	
									
									##verify port number
									if isdigit ${PORT_NUM} && [ ${PORT_NUM} -ge 1 ] && [ ${PORT_NUM} -le 65535 ]; then
										test_port=${SUCCESS}
									fi 
									##Verify mac address
									if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
										test_mac=${SUCCESS}
									fi 
									
									##verify vlan number
									if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
										test_vlan=${SUCCESS}
									fi	
									
									error_display ${test_mac} ${test_vlan} ${test_ip} ${SUCCESS} ${test_port}
									TEST_ERROR_FUNC_RETN=$?
									
									#setting values
									[ $TEST_ERROR_FUNC_RETN -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEL}"
											SOCKETi="-net socket"
											VLAN_SOCKETi=",vlan=${VLAN_NUM}"
											MCASTi=",mcast=${IP_ADDR}:${PORT_NUM}"
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}	
																						
											#break 3
									}									
								;;
								
							esac 													
						;;
						
						
						8) 
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
							
								exec 3>&1 ##create new file descriptor
							
								values=`${DIALOG} \
									--no-shadow --extra-button --output-separator "|" --trim --clear --colors \
									--title "\Zb\Z0Network\Zn\ZB" --default-button "Ok" --extra-label "Back" \
									--form "Use already Opened UDP multicast Socket \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
									"IP Address:" 2 1 "" 2 13 -18 15 "Port:" 2 32 "" 2 37 -6 6 \
									"MAC Address:" 3 1 "${MACADDR}" 3 13 18 0 "VLAN:" 3 32 "0" 3 37 6 4 \
									"File descriptor:" 5 1 "" 5 17 6 4 "TUN/TAP Script:" 7 1 "" 7 16 -27 58 \
									"Interface Name:" 8 1 "" 8 16 -27 58 2>&1 1>&3`						
								
								RETURN_CODE=$?
								exec 3>&- ##close file descriptor
								
								case ${RETURN_CODE} in 
								
									${DIALOG_BACK}) break ;;
									${DIALOG_CANCEL}) break 2 ;;
									${DIALOG_OK}) 
									
										MAC_ADDR=${values%%|*}
										VLAN_NUM=`echo $values|cut -d "|" -f2`
										FD_N=`echo $values|cut -d "|" -f3`
									
										##Verify mac address
										if [[ $MAC_ADDR =~ [[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]] ]]; then
											test_mac=${SUCCESS}
										fi 
										##verify vlan number
										if isdigit ${VLAN_NUM} && [ ${VLAN_NUM} -ge 0 ] && [ ${VLAN_NUM} -le 1000 ]; then
											test_vlan=${SUCCESS}
										fi	
									
										if isdigit ${FD_N} && [ ${FD_N} -ge 0 ] && [ ${FD_N} -le 1000 ]; then
											test_fd=${SUCCESS}
										fi		
									
										error_display ${test_mac} ${test_vlan} ${SUCCESS} ${test_fd} ${SUCCESS}
										TEST_ERROR_FUNC_RETN=$?
										
										#setting values
										[ $TEST_ERROR_FUNC_RETN -eq ${SUCCESS} ] && {
											
											VLANi=",vlan=${VLAN_NUM}"
											MACi=",macaddr=${MAC_ADDR}"
											MODELi=",model=${MODEL}"
											SOCKETi="-net socket"
											FD_SOCKETi=",fd=${FD_N}"
											
											set_parameters ${i} ${VLANi} ${MACi} ${MODELi} ${USERi} ${VLAN_USERi} ${TAPi} ${VLAN_TAPi} \
											${IFNAMEi} ${SCRIPTi} ${FD_TAPi} ${SOCKETi} ${VLAN_SOCKETi} ${LISTENi} ${CONNECTi} ${FD_SOCKETi} \
											${MCASTi}	
																						
											#break 3
										}										
									;;
								esac 	
							
							done												
						;;
					
					esac 
						
				#fi 
				
				let "TEST_ERROR_FUNC_RETN=${FAILURE}"
			
				[[ ${test_using_user_mode} -eq ${SUCCESS} ]] && {	
					
					test_using_user_mode=${FAILURE}
					
					#${DIALOG} \
					#	--clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB" \
					#	--yesno "\nDo you want to allow port redirection  for the Virtual Machine \Zb[adapter ${i}]\ZB" $((HEIGHT-7)) $((WIDTH-10)) 
					exec 3>&1
					
					value=`${DIALOG} \
						--no-shadow --no-tags --extra-button --output-separator "|" --clear --colors --title "\Zb\Z0Port Redirection And SMB\Zn\ZB" \
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
									--menu "Choose a Protocol \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 2 1 "TCP-Transmission Control Protocol" \
									2 "UDP-User Datagram Protocol" 2>&1 1>&3`
									
								exec 3>&-
								
								case ${value} in 
									1) 
										while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
											exec 3>&1
													
											values=`${DIALOG} \
												--no-shadow --output-separator "|" --trim --clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB"\
												--form "Port Redirection \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
												"On Host Port:" 2 2 "0" 2 15 6 5 "To Guest IP:" 4 2 "" 4 14 18 15 \
												"For Guest Port:" 6 2 "0" 6 17 6 5 2>&1 1>&3`
													
											let "test_return=$?"
											exec 3>&-
												
											case ${test_return} in 
												${DIALOG_CANCEL}) break ;;
												${DIALOG_OK}) 
														
													HOST_PORT_NUM=${values%%|*}
													GUEST_IP_ADDR=`echo $values|cut -d "|" -f2`
													GUEST_PORT_NUM=`echo $values|cut -d "|" -f3`
														
													if [ -z ${GUEST_IP_ADDR} ] || is_IP_Valid ${GUEST_IP_ADDR}; then
														test_ip=${SUCCESS}
													fi 	
															
													if isdigit ${HOST_PORT_NUM} && [ ${HOST_PORT_NUM} -ge 1 ] && [ ${HOST_PORT_NUM} -le 65535 ]; then
														test_port_host=${SUCCESS}
													fi 		
														
													if isdigit ${GUEST_PORT_NUM} && [ ${GUEST_PORT_NUM} -ge 1 ] && [ ${GUEST_PORT_NUM} -le 65535 ]; then
														test_port_guest=${SUCCESS}
													fi
													
													[[ ${test_port_guest} -eq ${SUCCESS} ]] && [[ ${test_port_host} -eq ${SUCCESS} ]] && { 
														test_port=${SUCCESS} 
													}
														
													error_display ${SUCCESS} ${SUCCESS} ${test_ip} ${SUCCESS} ${test_port}	
													TEST_ERROR_FUNC_RETN=$?
													
													#set parameters
													HOSTFWD="-net user,hostfwd=tcp:${HOST_IP}:${HOST_PORT_NUM}-${GUEST_IP_ADDR}:${GUEST_PORT_NUM}"
													[[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ]] && {
														
														set_parameters ${i} ${global_VLAN_FOR_USER_MODE} ${global_MAC_FOR_USER_MODE} \
														 ${global_MODEL_FOR_USER_MODE} ${HOSTFWD} ${global_VLAN_FOR_USER_MODE} "" "" "" \
														 "" "" "" "" "" "" "" ""	
													}
												;;
											esac
											
										done 
									;;
									2) 
										
										while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
											exec 3>&1
													
											values=`${DIALOG} \
												--no-shadow --output-separator "|" --trim --clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB"\
												--form "Port Redirection \Zb[adapter ${i}]\ZB" ${HEIGHT} ${WIDTH} 10 \
												"On Host Port:" 2 2 "0" 2 15 6 4 "To Guest IP:" 4 2 "" 4 14 18 15 \
												"For Guest Port:" 6 2 "0" 6 17 6 4 2>&1 1>&3`
												
											let "test_return=$?"
											exec 3>&-
													
											case ${test_return} in 
												${DIALOG_CANCEL}) break ;;
												${DIALOG_OK}) 
														
													HOST_PORT_NUM=${values%%|*}
													GUEST_IP_ADDR=`echo $values|cut -d "|" -f2`
													GUEST_PORT_NUM=`echo $values|cut -d "|" -f3`
														
													if [ -z ${GUEST_IP_ADDR} ] || is_IP_Valid ${GUEST_IP_ADDR}; then
														test_ip=${SUCCESS}
													fi 	
													
													if isdigit ${HOST_PORT_NUM} && [[ ${HOST_PORT_NUM} -ge 0 ]] && [[ ${HOST_PORT_NUM} -le 1000 ]]; then
														test_port_host=${SUCCESS}
													fi 		
													
													if isdigit ${GUEST_PORT_NUM} && [[ ${GUEST_PORT_NUM} -ge 0 ]] && [[ ${GUEST_PORT_NUM} -le 1000 ]]; then
														test_port_guest=${SUCCESS}
													fi
													
													[[ ${test_port_guest} -eq ${SUCCESS} ]] && [[ ${test_port_host} -eq ${SUCCESS} ]] && { 
														test_port=${SUCCESS} 
													}
													
													error_display ${SUCCESS} ${SUCCESS} ${test_ip} ${SUCCESS} ${test_port}	
													TEST_ERROR_FUNC_RETN=$?
													
													#set parameters
													HOSTFWD="-net user,hostfwd=udp:${HOST_IP}:${HOST_PORT_NUM}-${GUEST_IP_ADDR}:${GUEST_PORT_NUM}"
													[[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ]] && {
														
														set_parameters ${i} ${global_VLAN_FOR_USER_MODE} ${global_MAC_FOR_USER_MODE} \
														 ${global_MODEL_FOR_USER_MODE} ${HOSTFWD} ${global_VLAN_FOR_USER_MODE} "" "" "" \
														 "" "" "" "" "" "" "" ""	
													}								
												;;
											esac
													
										done 			
									;;
								esac
							fi 
							;;
							${DIALOG_CANCEL}) [[ ${NUM_ADAPTER} -eq ${i} ]] && break 2 ;;
						esac
				}
				
				fi 		
		done 
				
	fi 
	
	[ ${back_key_in_for_loop} -eq ${FAILURE} ] && break
	
done			

