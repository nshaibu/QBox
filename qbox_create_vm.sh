#!/bin/bash

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include '<disk_details.h>' ##include disk creation functions

if  NOT_DEFINE ${ARCHITECTURE_H} || NOT_DEFINE ${AUDIO_DISPLAY_H} || NOT_DEFINE ${BOOT_SYSTEM_H} || NOT_DEFINE ${CURSES_DIALOG_H} ; then
	. ${LIB_DIR}/include '<architecture.h>'
	. ${LIB_DIR}/include '<audio_display.h>'
	. ${LIB_DIR}/include '<boot_system.h>'
	. ${LIB_DIR}/include '<curses_dialog.h>'
fi 

if NOT_DEFINE ${HOST_IP_H} || NOT_DEFINE ${VNC_INFO_H} || NOT_DEFINE ${TRUE_TEST_H} ; then
	. ${LIB_DIR}/include '<host_ip.h>'
	. ${LIB_DIR}/include '<vnc_info.h>'
	. ${LIB_DIR}/include '<true_test.h>'
fi  



##ARRAY CONTAINERS FOR INFO OF OSes
declare -a ARR_MICROSOFT_WINDOWS=("Windows3.1|32M|1G" "Windows95|64M|2G" "Windows98|64M|2G" "WindowsME|128M|4G" \
								"WindowsNT4|128M|2G" "Windows2000|168M|4G" "WindowsXP[32bit]|192M|10G" "WindowsXP[64bit]|512M|10G" \
								"Windows2003[32bit]|512M|20G" "Windows2003[64bit]|512M|20G" "WindowsVista[32bit]|512M|25G" \
								"WindowsVista[64bit]|512M|25G" "Windows2008[32bit]|512M|25G" "Windows2008[64bit]|512M|25G" \
								"Windows7[32bit]|512M|25G" "Windows7[64bit]|512M|25G" "Windows8[32bit]|1024M|25G" "Windows8[64bit]|2048M|25G" \
								"Windows8.1[32bit]|1024M|25G" "Windows8.1[64bit]|2048M|25G" "Windows2012[64bit]|2048M|25G" \
								"Windows10[32bit]|1048M|32G" "Windows10[64bit]|2048M|32G" "OtherWindows[32bit]|512M|20G" "OtherWindows[64bit]|512M|20G")
								
declare -a ARR_LINUX=("Linux2.2|64M|2G" "Linux2.4[32bit]|128M|4G" "Linux2.4[64bit]|128M|4G" "Linux2.6->4[32bit]|256M|8G" "Linux2.6->4[64bit]|256M|8G" \
					  "ArchLinux[32bit]|768M|8G" "ArchLinux[64bit]|768M|8G" "Debian[32bit]|768M|8G" "Debian[64bit]|768M|8G" "OpenSUSE[32bit]|768M|8G" \
					  "OpenSUSE[64bit]|768M|8G" "Fedora[32bit]|768M|8G" "Fedora[64bit]|768M|8G" "Gentoo[32bit]|768M|8G" "Gentoo[64bit]|768M|8G" \
					  "Mandriva[32bit]|512M|8G" "Mandriva[64bit]|512M|8G" "Redhat[32bit]|768M|8G" "Redhat[64bit]|768M|8G" "TurboLinux[32bit]|384M|8G" \
					  "TurboLinux[64bit]|384M|8G" "Ubuntu[32bit]|768M|8G" "Ubuntu[64bit]|768M|8G" "Xandros[32bit]|256M|8G" "Xandros[64bit]|256M|8G" \
					  "Oracle[32bit]|768M|12G" "Oracle[64bit]|768M|12G" "OtherLinux[32bit]|256M|8G" "OtherLinux[64bit]|512M|8G" )
					  
declare -a ARR_SOLARIS=("Oracle_Solaris10-5/09AndEarlier[32bit]|768M|16G" "Oracle_Solaris10-5/09AndEarlier[64bit]|1536M|16G" \
						"Oracle_Solaris10-10/09AndLater[32bit]|768M|16G" "Oracle_Solaris10-10/09AndLater[32bit]|1536M|16G" \
						"Oracle_Solaris11[64bit]|1536M|16G" )

declare -a ARR_BSD=("FreeBSD[32bit]|128M|2G" "FreeBSD[64bit]|128M|2G" "OpenBSD[32bit]|64M|2G" "OpenBSD[64bit]|64M|2G" "NetBSD[32bit]|64M|2G" \
					"NetBSD[64bit]|64M|2G" )

declare -a ARR_IBMOS2=("OS/2_Warp_3|48M|1G" "OS/2_Warp_4|64M|2G" "OS/2_Warp_4.5|128M|2G" "eComStation|256M|2G" "OS/2.1.x|8M|500M" \
					   "Other_OS/2|96M|2G" )

declare -a ARR_MACOSX=("Mac_OSX[32bit]|2048M|20G" "Mac_OSX[64bit]|4048M|20G" "Mac_OSX10.6Snow_Leopard[32bit]|2048M|20G" \
					   "Mac_OSX10.6Snow_Leopard[64bit]|2048M|20G" "Mac_OSX10.7Lion[64bit]|2048M|20G" "Mac_OSX10.8Mountain_Lion[64bit]|2048M|20G" \
					   "Mac_OSX10.9Mavericks[64bit]|2048M|20G" "Mac_OSX10.10Yosemite[64bit]|2048M|20G" "Mac_OSX10.11El_Capitan[64bit]|2048M|20G" )

declare -a ARR_OTHEROS=("DOS|32M|500M" "NetWare|512M|4G" "L4|64M|2G" "QNX|512M|4G" "JRockitVE|1024M|8G" "Unknown|64M|2G" "Unknown[64bit]|64M|2G" )
declare -a ARR_OS_TYPE=("Microsoft Windows" "Linux" "Solaris" "BSD" "IBM OS/2" "Mac OS X" "Other")

export SDL_VIDEO_X11_DGAMOUSE=0 ##to prevent qemu cursor from been difficult to control

declare -i HEIGHT=18
declare -i WIDTH=50


function isdigit(){
	if [ -z "$1" ]; then
		return 	$FAILURE
	fi 
	
	case "$1" in 
		[[:digit:]]|[[:digit:]]*) return $SUCCESS ;;
		*)	return $FAILURE ;;
	esac
}


function error_display(){ 
	
	. ${LIB_DIR}/include "<error.h>"
	
	local _return=${SUCCESS}
	
	[ $1 -eq ${SUCCESS} ] && [ $2 -eq ${SUCCESS} ] && [ $3 -eq ${SUCCESS} ] && [ $4 -eq ${SUCCESS} ] && [ $5 -eq ${SUCCESS} ] || {
	
			if [[ $1 -eq ${FAILURE} ]]; then
				mac_err_str="|* Name is not unique or Name is empty"
				_return=${FAILURE}
			elif [[ $2 -eq ${FAILURE} ]]; then
				vlan_err_str="|* Input not valid.Input cannot be less than one and it should be in the format [0-9][G,M] eg.10G"
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

##unique for the vms. The name is used as the primary key for vms database
function is_VMName_unique(){
	local _return=${FAILURE}
	local search="^$1\$"
	local unique=$(gawk -F "|" -v var=$search '$1 ~ var {print $1}' ${QDB_FOLDER}/vms.qdb 2>/dev/null)
	[ -z ${unique} ] && _return=${SUCCESS}
	return ${_return}
}


function disk_size_valid(){
#Sat 28 Jan 2017 12:18:24 AM GMT 
	local tmp=$1
	if [[ -z "$1" ]]; then
		return ${FAILURE}
	fi 
	
	local first_part=${tmp%%[[:alpha:]]*}
	local second_part=${tmp##*[[:digit:]]}
	
	isdigit ${first_part} && [[ ${first_part} -ge 1 ]] && [[ ${second_part} =~ [[:alpha:]] ]] && [[ "${second_part}" = "G" || "${second_part}" = "M" ]] && { return ${SUCCESS}; } 
	
	return ${FAILURE}
}

while [ 1 ]; do 
	
	let "TEST_ERROR_FUNC_RETN=${FAILURE}"
	let "test_vmname=${FAILURE}"
	
	while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do 
		
		exec 3>&1
		
		value=`${DIALOG} \
				--no-shadow --clear --ok-label "Next" --trim --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
				--form "\Zb\Z0Identification\Zn\ZB\nChoose a name for the VM. The name should not contain \Zb\Z0white spaces\Zn\ZB and \"\Zb\Z0|\Zn\ZB\".\
				If possible choose a descriptive name. The length of the name should be at most \Zb\Z018 characters\Zn\ZB \
				long. The name choosen should be \Zb\Z0unique\Zn\ZB." ${HEIGHT} ${WIDTH} 3 "Name:" 2 2 "" 2 7 37 18 2>&1 1>&3`
	
		let "return_dialog=$?"
		exec 3>&-
		
		if [[ ${return_dialog} -eq ${DIALOG_CANCEL} ]]; then
			break 2
		fi 
		
		value=${value// /_}
		vm_name=${value//|/}
		vm_name=$(echo $vm_name | awk '{print toupper($0)}')
			
		if [[ -n $vm_name ]] && is_VMName_unique $vm_name ; then
			test_vmname=${SUCCESS}
		fi 
		
		error_display ${test_vmname} ${SUCCESS} ${SUCCESS} ${SUCCESS} ${SUCCESS}
		TEST_ERROR_FUNC_RETN=$?
			
		if [[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ]]; then
			let "TEST_ERROR_FUNC_RETN=${FAILURE}"
			
			VM_NAME=$value # set vm name 
			
			while true ; do 
				exec 3>&1
				value_=`${DIALOG} \
					--no-shadow --clear --ok-label "Next" --extra-button --extra-label "Back" --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
					--menu "\Zb\Z0Identification\Zn\ZB\nChoose the type of Operating system" ${HEIGHT} ${WIDTH} 7 \
					1 "${ARR_OS_TYPE[0]}" 2 "${ARR_OS_TYPE[1]}" 3 "${ARR_OS_TYPE[2]}" 4 "${ARR_OS_TYPE[3]}" 5 "${ARR_OS_TYPE[4]}" \
					6 "${ARR_OS_TYPE[5]}" 7 "${ARR_OS_TYPE[6]}" 2>&1 1>&3`
						
					let "return_test=$?"
					exec 3>&-
					
					case ${return_test} in 
						${DIALOG_OK}) 
								
							case ${value_} in 
								1) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_MICROSOFT_WINDOWS[0]%%|*}" 2 "${ARR_MICROSOFT_WINDOWS[1]%%|*}" 3 "${ARR_MICROSOFT_WINDOWS[2]%%|*}" \
										 4 "${ARR_MICROSOFT_WINDOWS[3]%%|*}" 5 "${ARR_MICROSOFT_WINDOWS[4]%%|*}" 6 "${ARR_MICROSOFT_WINDOWS[5]%%|*}" \
										 7 "${ARR_MICROSOFT_WINDOWS[6]%%|*}" 8 "${ARR_MICROSOFT_WINDOWS[7]%%|*}" 9 "${ARR_MICROSOFT_WINDOWS[8]%%|*}" \
										 10 "${ARR_MICROSOFT_WINDOWS[9]%%|*}" 11 "${ARR_MICROSOFT_WINDOWS[10]%%|*}" 12 "${ARR_MICROSOFT_WINDOWS[11]%%|*}" \
										 13 "${ARR_MICROSOFT_WINDOWS[12]%%|*}" 14 "${ARR_MICROSOFT_WINDOWS[13]%%|*}" 15 "${ARR_MICROSOFT_WINDOWS[14]%%|*}" \
										 16 "${ARR_MICROSOFT_WINDOWS[15]%%|*}" 17 "${ARR_MICROSOFT_WINDOWS[16]%%|*}" 18 "${ARR_MICROSOFT_WINDOWS[17]%%|*}" \
										 19 "${ARR_MICROSOFT_WINDOWS[18]%%|*}" 20 "${ARR_MICROSOFT_WINDOWS[19]%%|*}" 21 "${ARR_MICROSOFT_WINDOWS[20]%%|*}" \
										 22 "${ARR_MICROSOFT_WINDOWS[21]%%|*}" 23 "${ARR_MICROSOFT_WINDOWS[22]%%|*}" 24 "${ARR_MICROSOFT_WINDOWS[23]%%|*}" \
										 25 "${ARR_MICROSOFT_WINDOWS[24]%%|*}" 2>&1 1>&3`
									
									let "test_return=$?"
									exec 3>&-
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case $value in 
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[1]} | cut -d "|" -f3`				
											;;
											3) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[4]} | cut -d "|" -f3`				
											;;
											6) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[5]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[5]} | cut -d "|" -f3`				
											;;
											7) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[6]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[6]} | cut -d "|" -f3`				
											;;
											8) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f3`				
											;;
											9) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f3`				
											;;
											10) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f3`				
											;;
											11) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[10]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[10]} | cut -d "|" -f3`				
											;;
											12) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[11]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[11]} | cut -d "|" -f3`				
											;;
											13) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[12]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[12]} | cut -d "|" -f3`				
											;;
											14) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[13]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[13]} | cut -d "|" -f3`				
											;;
											15) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[14]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[14]} | cut -d "|" -f3`				
											;;
											16) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[15]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[15]} | cut -d "|" -f3`				
											;;
											17) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[16]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[16]} | cut -d "|" -f3`				
											;;
											18) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[17]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[17]} | cut -d "|" -f3`				
											;;
											19) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[18]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[18]} | cut -d "|" -f3`				
											;;
											20) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[19]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[19]} | cut -d "|" -f3`				
											;;
											21) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[20]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[20]} | cut -d "|" -f3`				
											;;
											22) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[21]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[21]} | cut -d "|" -f3`				
											;;
											23) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[22]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[22]} | cut -d "|" -f3`				
											;;
											24) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[23]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[23]} | cut -d "|" -f3`				
											;;
											25) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[24]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[24]} | cut -d "|" -f3`				
											;;
											1) 
												RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[0]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[0]} | cut -d "|" -f3`
											;;				
										esac	
										break 2
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										: 
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 
								;;
								2) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_LINUX[0]%%|*}" 2 "${ARR_LINUX[1]%%|*}" 3 "${ARR_LINUX[2]%%|*}" \
										 4 "${ARR_LINUX[3]%%|*}" 5 "${ARR_LINUX[4]%%|*}" 6 "${ARR_LINUX[5]%%|*}" \
										 7 "${ARR_LINUX[6]%%|*}" 8 "${ARR_LINUX[7]%%|*}" 9 "${ARR_LINUX[8]%%|*}" \
										 10 "${ARR_LINUX[9]%%|*}" 11 "${ARR_LINUX[10]%%|*}" 12 "${ARR_LINUX[11]%%|*}" \
										 13 "${ARR_LINUX[12]%%|*}" 14 "${ARR_LINUX[13]%%|*}" 15 "${ARR_LINUX[14]%%|*}" \
										 16 "${ARR_LINUX[15]%%|*}" 17 "${ARR_LINUX[16]%%|*}" 18 "${ARR_LINUX[17]%%|*}" \
										 19 "${ARR_LINUX[18]%%|*}" 20 "${ARR_LINUX[19]%%|*}" 21 "${ARR_LINUX[20]%%|*}" \
										 22 "${ARR_LINUX[21]%%|*}" 23 "${ARR_LINUX[22]%%|*}" 24 "${ARR_LINUX[23]%%|*}" \
										 25 "${ARR_LINUX[24]%%|*}" 26 "${ARR_LINUX[25]%%|*}" 27 "${ARR_LINUX[26]%%|*}" \
										 28 "${ARR_LINUX[27]%%|*}" 29 "${ARR_LINUX[28]%%|*}" 2>&1 1>&3`
									let "test_return=$?"
									exec 3>&-
									
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case ${value} in 
											1) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[0]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[0]} | cut -d "|" -f3`
											;;			
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[1]} | cut -d "|" -f3`				
											;;
											3) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[4]} | cut -d "|" -f3`				
											;;
											6) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[5]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[5]} | cut -d "|" -f3`				
											;;
											7) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[6]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[6]} | cut -d "|" -f3`				
											;;
											8) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[7]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[7]} | cut -d "|" -f3`				
											;;
											9) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[8]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[8]} | cut -d "|" -f3`				
											;;
											10) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[9]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[9]} | cut -d "|" -f3`				
											;;
											11) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[10]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[10]} | cut -d "|" -f3`				
											;;
											12) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[11]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[11]} | cut -d "|" -f3`				
											;;
											13) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[12]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[12]} | cut -d "|" -f3`				
											;;
											14) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[13]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[13]} | cut -d "|" -f3`				
											;;
											15) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[14]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[14]} | cut -d "|" -f3`				
											;;
											16) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[15]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[15]} | cut -d "|" -f3`				
											;;
											17) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[16]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[16]} | cut -d "|" -f3`				
											;;
											18) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[17]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[17]} | cut -d "|" -f3`				
											;;
											19) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[18]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[18]} | cut -d "|" -f3`				
											;;
											20) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[19]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[19]} | cut -d "|" -f3`				
											;;
											21) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[20]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[20]} | cut -d "|" -f3`				
											;;
											22) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[21]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[21]} | cut -d "|" -f3`				
											;;
											23) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[22]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[22]} | cut -d "|" -f3`				
											;;
											24) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[23]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[23]} | cut -d "|" -f3`				
											;;
											25) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[24]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[24]} | cut -d "|" -f3`				
											;;
											26) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[25]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[25]} | cut -d "|" -f3`				
											;;
											27) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[26]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[26]} | cut -d "|" -f3`				
											;;
											28) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[27]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[27]} | cut -d "|" -f3`				
											;;
											29) 
												RECOM_RAM_SIZE=`echo ${ARR_LINUX[28]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_LINUX[28]} | cut -d "|" -f3`				
											;;	
										esac	
										break 2	
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										: 
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 		
								;;
								3) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_SOLARIS[0]%%|*}" 2 "${ARR_SOLARIS[1]%%|*}" 3 "${ARR_SOLARIS[2]%%|*}" \
										 4 "${ARR_SOLARIS[3]%%|*}" 5 "${ARR_SOLARIS[4]%%|*}" 2>&1 1>&3`
									
									let "test_return=$?"
									exec 3>&-
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case $value in 
											
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_SOLARIS[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_SOLARIS[1]} | cut -d "|" -f3`				
											;;
											3) 
												RECOM_RAM_SIZE=`echo ${ARR_SOLARIS[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_SOLARIS[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_SOLARIS[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_SOLARIS[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_SOLARIS[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_SOLARIS[4]} | cut -d "|" -f3`				
											;;
											1) 
												RECOM_RAM_SIZE=`echo ${ARR_SOLARIS[0]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_SOLARIS[0]} | cut -d "|" -f3`
											;;				
										esac	
										break 2
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										: 
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 					
								;;
								4) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_BSD[0]%%|*}" 2 "${ARR_BSD[1]%%|*}" 3 "${ARR_BSD[2]%%|*}" \
										 4 "${ARR_BSD[3]%%|*}" 5 "${ARR_BSD[4]%%|*}" 6 "${ARR_BSD[5]%%|*}" 2>&1 1>&3`
									
									let "test_return=$?"
									exec 3>&-	
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case $value in 
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_BSD[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_BSD[1]} | cut -d "|" -f3`				
											;;
											3) 
												RECOM_RAM_SIZE=`echo ${ARR_BSD[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_BSD[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_BSD[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_BSD[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_BSD[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_BSD[4]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_BSD[5]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_BSD[5]} | cut -d "|" -f3`				
											;;
											1) 
												OS_VERSION=`echo ${ARR_BSD[0]} | cut -d "|" -f1`
												RECOM_RAM_SIZE=`echo ${ARR_BSD[0]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_BSD[0]} | cut -d "|" -f3`
											;;
										esac	
										break 2			
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										:
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 
								;;
								5) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_IBMOS2[0]%%|*}" 2 "${ARR_IBMOS2[1]%%|*}" 3 "${ARR_IBMOS2[2]%%|*}" \
										 4 "${ARR_IBMOS2[3]%%|*}" 5 "${ARR_IBMOS2[4]%%|*}" 6 "${ARR_IBMOS2[5]%%|*}" 2>&1 1>&3`
									
									let "test_return=$?"
									exec 3>&-	
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case $value in 
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[1]} | cut -d "|" -f3`				
											;;
											3) 
												RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[4]} | cut -d "|" -f3`				
											;;
											6) 
												RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[5]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[5]} | cut -d "|" -f3`				
											;;
											1) 
												RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[0]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[0]} | cut -d "|" -f3`
											;;				
										esac	
										break 2
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										:
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 					
								;;
								6) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_MACOSX[0]%%|*}" 2 "${ARR_MACOSX[1]%%|*}" 3 "${ARR_MACOSX[2]%%|*}" \
										 4 "${ARR_MACOSX[3]%%|*}" 5 "${ARR_MACOSX[4]%%|*}" 6 "${ARR_MACOSX[5]%%|*}" \
										 7 "${ARR_MACOSX[6]%%|*}" 8 "${ARR_MACOSX[7]%%|*}" 9 "${ARR_MACOSX[8]%%|*}" 2>&1 1>&3`
									
									let "test_return=$?"
									exec 3>&-
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case $value in 
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[1]} | cut -d "|" -f3`				
											;;
											3) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[4]} | cut -d "|" -f3`				
											;;
											6) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[5]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[5]} | cut -d "|" -f3`				
											;;
											7) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[6]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[6]} | cut -d "|" -f3`				
											;;
											8) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[7]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[7]} | cut -d "|" -f3`				
											;;
											9) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[8]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[8]} | cut -d "|" -f3`				
											;;
											1) 
												RECOM_RAM_SIZE=`echo ${ARR_MACOSX[0]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_MACOSX[0]} | cut -d "|" -f3`
											;;				
										esac	
										break 2
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										:
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 	
								;;
								7) 
									exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--menu "\Zb\Z0Identification\Zn\ZB\nChoose the version of ${ARR_OS_TYPE[$((value_-1))]}" ${HEIGHT} ${WIDTH} 7 \
										 1 "${ARR_OTHEROS[0]%%|*}" 2 "${ARR_OTHEROS[1]%%|*}" 3 "${ARR_OTHEROS[2]%%|*}" \
										 4 "${ARR_OTHEROS[3]%%|*}" 5 "${ARR_OTHEROS[4]%%|*}" 6 "${ARR_OTHEROS[5]%%|*}" \
										 7 "${ARR_OTHEROS[6]%%|*}" 2>&1 1>&3`
									
									let "test_return=$?"
									exec 3>&-
									if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
										case $value in 
											2) 
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[1]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[1]} | cut -d "|" -f3`				
											;;
											3)
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[2]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[2]} | cut -d "|" -f3`				
											;;
											4) 
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[3]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[3]} | cut -d "|" -f3`				
											;;
											5) 
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[4]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[4]} | cut -d "|" -f3`				
											;;
											6) 
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[5]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[5]} | cut -d "|" -f3`				
											;;
											7) 
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[6]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[6]} | cut -d "|" -f3`				
											;;
											1) 
												RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[${index}]} | cut -d "|" -f2`
												RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[${index}]} | cut -d "|" -f3`				
											;;				
										esac	
										break 2
									elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
										:
									elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
										break 3
									fi 		
								;;
							esac 
						;;
						${DIALOG_CANCEL}) break 3 ;;
						${DIALOG_BACK}) break ;;
					esac
			done
		fi 
	done 
	
	while [ 1 ]; do 
		exec 3>&1
		value=`${DIALOG} \
			--clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
			--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
			--rangebox "\Zb\Z0Memory Size\Zn\ZB \nSelect the amount of memory(RAM) in Megabytes to be allocated to the virtual machine.This is done by moving the slider below using the following keys:\n  * \Zb\Z0[-/+]\Zn\ZB increase/decrease the slider\n  * \Zb\Z0[0-9]\Zn\ZB set slider to that value\n  * \Zb\Z0[home/end]\Zn\ZB set the value to its max/min\n  * \Zb\Z0[pageup/pagedown]\Zn\ZB increment the value\n\n Recommended RAM size \Zb\Z0${RECOM_RAM_SIZE}\Zn\ZB " ${HEIGHT} ${WIDTH} 4 4096 ${RECOM_RAM_SIZE%%[[:alpha:]]} 2>&1 1>&3`
			
			let "test_return=$?"
			exec 3>&-
			
			if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
				RAM_SIZE=$value 
				
				while [ 1 ]; do 
					exec 3>&1
					value=`${DIALOG} \
						--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
						--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
						--menu "\Zb\Z0Hard Disk File Formats\Zn\ZB \nChoose a file format that will be used by the virtual machine. Recommended formats are QCOW2 and RAW" \
						${HEIGHT} ${WIDTH} 5 \
						 1 "QCOW2(QEMU Copy-On-Write)" 2 "RAW(Raw disk image format)" 3 "QED(QEMU Enhanced Disk)" \
						 4 "VMDK(Virtual Machine Disk)" 5 "VDI(Virtual Disk Image)"  2>&1 1>&3`
									
					let "test_return=$?"
					exec 3>&-
					
					case ${test_return} in 
						${DIALOG_OK}) 
							DISK_FORMAT=$value
							
							let "TEST_ERROR_FUNC_RETN=${FAILURE}"
							
							while [[ ${TEST_ERROR_FUNC_RETN} -ne ${SUCCESS} ]]; do
								exec 3>&1
									value=`${DIALOG} \
										--no-shadow --clear  --extra-button --extra-label "Back" --ok-label "Create" --trim --colors \
										--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
										--form "\Zb\Z0Disk Size And Creation\Zn\ZB \nEnter the amount of space in Megabytes or Gigabytes to be allocated to the virtual machine as hard disk space.It should be in this format: \n       \Zb\Z0[0-9][G,M]\Zn\ZB. \nRecommended disk size \Zb\Z0${RECOM_DISK_SIZE}\Zn\ZB. " ${HEIGHT} ${WIDTH} 3 "Disk Size:" 2 2 "${RECOM_DISK_SIZE}" 2 12 29 6 2>&1 1>&3`
								
									let "test_return=$?"
								exec 3>&-	
							
								case ${test_return} in 
									${DIALOG_OK}) 
										disk_size_valid $value
										error_display ${SUCCESS} $? ${SUCCESS} ${SUCCESS} ${SUCCESS}
										TEST_ERROR_FUNC_RETN=$?
										
										if [[ ${TEST_ERROR_FUNC_RETN} -eq ${SUCCESS} ]]; then
											DISK_SIZE=$value
											
											disk_image_creation ${DISK_FORMAT} ${Disk_Name} ${DISK_SIZE}
											TEST_ERROR_FUNC_RETN_c=$?
											
											[[ ${TEST_ERROR_FUNC_RETN_c} -eq 1 ]] && {
												${DIALOG} \
													--colors --extra-button  --extra-label "Cancel" --clear --ok-label "Continue" \
													--title "\Zb\Z1Error Occured\Zn\ZB" \
													--msgbox "\n\nDisk creation failed!!!\nDo you want to continue?" \
													$((HEIGHT-7)) $((WIDTH-10))
													
												case $? in 
													${DIALOG_OK}) break 2 ;;
													${DIALOG_BACK}) rm -f ${Disk_Name} 2>/dev/null 2>&1; break 4 ;;
												esac
											}
											break 2
										fi 
									;;
									${DIALOG_BACK}) break;;
									${DIALOG_CANCEL}) break 4;;
								esac 
							done 
						;;
						${DIALOG_BACK}) break ;;
						${DIALOG_CANCEL}) break 3;;
					esac
				done
			elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
				break
			elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
				break 2
			fi 
			
#			${DIALOG} \
#				--clear --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
#				--yesno "\nDo you want to enable sound for the Virtual Machine" $((HEIGHT-7)) $((WIDTH-10)) 
				exec 3>&1
					
			value=`${DIALOG} \
				--no-shadow --no-tags --output-separator "|" --clear --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
				--checklist "\Zb\Z0Enable Fullscreen And Audio\Zn\ZB \nWhen you enable fullscreen for Virtual Machine you can switch back to windows mode by using the key combinations \Zb\Z0ctrl+Alt+f\Zn\ZB. \nEnable audio and selected sound hardware. \n\nPress the \Zb\Z0SPACE-KEY\Zn\ZB to make a choice" ${HEIGHT} ${WIDTH} 2 1 "Start in Fullscreen Mode" off 2 "Enable Audio" off 2>&1 1>&3`
				
				let "test_return=$?"
				exec 3>&-
				
				tmp_value=${value#*|}
				declare -i value_fullscrn=${tmp_value%%|*}
				declare -i value_audio=${value##*|}
				
				case ${test_return} in 
					${DIALOG_OK}) 
						[[ "$value_fullscrn" = "2" ]] && {
							exec 3>&1
							value=`${DIALOG} \
								--no-shadow --colors --nook --nocancel --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
								--menu "\Zb\Z0Audio\Zn\ZB \nChoose an audio controller for the Virtual Machine" ${HEIGHT} ${WIDTH} 4 \
								1 "Creative SoundBlaster 16 sound card" 2 "ENSONIQ AudioPCI ES1370 sound card" \
								3 "Intel HD Audio Controller and HDA codec" 2>&1 1>&3`
						
							exec 3>&-
					
								case "$value" in 
									1) QEMU_SOUND="-soundhw sb16" ;;
									2) QEMU_SOUND="-soundhw es1370" ;;
									3) QEMU_SOUND="-soundhw hda" ;;
								esac
						}
						
						[[ "$value_redir" = "1" ]] && { QEMU_FULLSCREEN="-full-screen"; }
					;;
					${DIALOG_CANCEL}) ;;
				esac
			
			while [ 1 ]; do 
				exec 3>&1
				
				value=`${DIALOG} \
				--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
				--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
				--menu "\Zb\Z0Display\Zn\ZB \nChoose a display for the Virtual Machine" ${HEIGHT} ${WIDTH} 4 \
				1 "Display video output via SDL" 2 "Display video output via curses" \
				3 "Display video output via VNC" 2>&1 1>&3`
				
				let "test_return=$?"
				exec 3>&-
				 
					if [[ ${test_return} -eq ${DIALOG_OK} ]]; then
						case ${value} in 
							2) DISPLAY="-display curses" ;;
							1) DISPLAY="-display sdl" ;;
							3)
								DISPLAY="-display vnc=:${VNC_DISPLAY}"
								${DIALOG} \
									--clear --colors --title "\Zb\Z0VNC ACCESS\Zn\ZB" \
									--msgbox "\nTo view the Virtual Machine.Enter:\n\n   \Zb\Z0[vncviewer] ${HOST_IP}:${VNC_PORT}\Zn\ZB" \
									$((HEIGHT-7)) $((WIDTH-10))
							;;
						esac
						
						while [ 1 ]; do 
							exec 3>&1
#							Fri 10 Feb 2017 10:02:36 PM GMT 
							value=`${DIALOG} \
							--no-shadow --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
							--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
							--menu "\Zb\Z0Display\Zn\ZB \nChoose a video card for the Virtual Machine" ${HEIGHT} ${WIDTH} 4 \
							1 "Cirrus Logic GD5446 Video card" 2 "Standard VGA card with Bochs VBE" 2>&1 1>&3`
							
							let "test_return=$?"
							exec 3>&-
							
							case ${test_return} in 
								${DIALOG_OK}) 
									[[ $value -eq 1 ]] && VGA="-vga cirrus" || VGA="-vga std" 
									
									while [ 1 ]; do 
										exec 3>&1
											
										value=`${DIALOG} \
											--clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
											--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
											--rangebox "\Zb\Z0Number Of CPU Cores\Zn\ZB \nSelect the number of CPU cores to be emulated for the virtual machine.This is done by moving the slider below using the following keys:\n  * \Zb\Z0[-/+]\Zn\ZB increase/decrease the slider\n  * \Zb\Z0[0-9]\Zn\ZB set slider to that value\n  * \Zb\Z0[home/end]\Zn\ZB set the value to its max/min\n  * \Zb\Z0[pageup/pagedown]\Zn\ZB increment the value\n " ${HEIGHT} ${WIDTH} 1 4 1 2>&1 1>&3`						
										let "test_return=$?"
										exec 3>&-
										
										case ${test_return} in 
											${DIALOG_OK}) 
												NUM_CPU="-cpu host -smp $value"
#												Fri 10 Feb 2017 10:42:45 PM GMT 
												
												while true; do 
													exec 3>&1
													value=`${DIALOG} \
														--no-tags --clear --extra-button --extra-label "Back" --ok-label "Next" --colors  \
														--title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
														--radiolist "\Zb\Z0Pointing device\Zn\ZB \nChoose a Pointing device for the Virtual Machine. The \Zb\Z0Default\Zn\ZB mean disable. \Zb\Z0Mouse\Zn\ZB will override the PS/2 mouse emulation when activated. \Zb\Z0tablet\Zn\ZB Pointer device uses absolute coordinates (like a touchscreen). This means QEMU is able to report the mouse position without having to grab the mouse.\nPress \Zb\Z0SPACE-KEY\Zn\ZB to make a choose" ${HEIGHT} ${WIDTH} 3 1 "Default" on 2 "Mouse" off 3 "Tablet" off 2>&1 1>&3`
												
													let "test_return=$?"
													exec 3>&-
												
													case ${test_return} in 
														${DIALOG_OK}) 
															pointing_dev_choice $value
															####################Sun 12 Feb 2017 05:27:01 PM GMT 
														;;
														${DIALOG_BACK}) break ;;
														${DIALOG_CANCEL}) rm -f Disk_Name; break 6 ;;
													esac
													
												done
												
											;;
											${DIALOG_BACK}) break ;;
											${DIALOG_CANCEL}) break 6 ;;
										esac
											
									done									
								;;
								${DIALOG_BACK}) rm -f ${Disk_Name} 2>/dev/null 2>&1; break ;;
								${DIALOG_CANCEL}) rm -f ${Disk_Name} 2>/dev/null 2>&1; break 4 ;;
							esac 
						done 
						
					elif [[ ${test_return} -eq ${DIALOG_BACK} ]]; then
						rm -f ${Disk_Name} 2>/dev/null 2>&1
						break
					elif [[ ${test_return} -eq ${DIALOG_CANCEL} ]]; then
						rm -f ${Disk_Name} 2>/dev/null 2>&1
						break 4
					fi 
				
			done 
	done
done