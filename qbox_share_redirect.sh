#!/bin/bash


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
						--menu "Choose a Protocol \Zb[adapter $1]\ZB" ${HEIGHT} ${WIDTH} 2 1 "TCP-Transmission Control Protocol" \
						2 "UDP-User Datagram Protocol" 2>&1 1>&3`
									
				exec 3>&-
								
				case ${value} in 
					1) 
						while [[ ${TEST_ERROR_OCURRED} -eq ${SUCCESS} ]]; do
							exec 3>&1
													
								values=`${DIALOG} \
									--no-shadow --output-separator "|" --trim --clear --colors --title "\Zb\Z0VM Port Redirection\Zn\ZB"\
									--cancel-label "Back" --form "Port Redirection \Zb[adapter $1]\ZB" ${HEIGHT} ${WIDTH} 10 \
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
										 ${global_MODEL_FOR_USER_MODE} ${HOSTFWD} ${global_VLAN_FOR_USER_MODE} "" "" "" \
														 "" "" "" "" "" "" "" ""	
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
									--cancel-label "Back" --form "Port Redirection \Zb[adapter $1]\ZB" ${HEIGHT} ${WIDTH} 10 \
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
														
										set_parameters ${j} "" ${global_MAC_FOR_USER_MODE} \
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
		${DIALOG_CANCEL}) break 2 ;;
	esac
