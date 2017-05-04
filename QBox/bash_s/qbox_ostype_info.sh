#!bin/bash

#===========================================================================================
# Copyright (C) 2017 Nafiu Shaibu.
# Purpose: OS ram and disk recommended size
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
declare -a ARR_OS_TYPE=("Microsoft Windows" "Linux" "Solaris" "BSD" "IBM OS/2" "Mac OS X" "Other" "Quit")

declare DELAY_TIME=0.12
RECOM_DISK_SIZE=""
RECOM_RAM_SIZE=""
OS_VERSION=""

########################################################
#													   #
#			DISPLAY FORMATED OUTPUT OF				   #
#				ARRAY CONTAINERS					   #
#													   #
#	This is done by control cursor positions		   #
#													   #
#													   #
#													   #
########################################################
function _display_Ostype_(){
	clear
	
	if [[ $1 = "%WINDOWS%" ]]; then
		
		tput bold
		echo -e "\t\t\t Versions of Microsoft Windows"
		tput sgr0
		for (( pass=0; pass<3; pass++ ))
		do
			if [[ $pass -eq 0 ]]; then
				ADJUST_BY=0
				X_CURSOR_POS=2
				Y_CURSOR_POS=3
			elif [[ $pass -eq 1 ]]; then
				ADJUST_BY=8
				X_CURSOR_POS=24
				Y_CURSOR_POS=3
			else
				ADJUST_BY=16
				X_CURSOR_POS=49
				Y_CURSOR_POS=3
			fi 
			
			for (( index=0; index<8; index++ ))
			do
				tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
				printf "%d) %s" $(( index + ADJUST_BY )) `echo ${ARR_MICROSOFT_WINDOWS[$(( index + ADJUST_BY ))]} | cut -d "|" -f1`
				
				LOOP_AT_23_COND=$(( index + ADJUST_BY )) ##Test when loop index gets to 23
				
				[[ ${LOOP_AT_23_COND} -eq 23 ]] && {
					tput cup $(( Y_CURSOR_POS + index + 1 )) ${X_CURSOR_POS}
					printf "%d) %s" $(( index + ADJUST_BY + 1 )) `echo ${ARR_MICROSOFT_WINDOWS[$(( index + ADJUST_BY + 1 ))]} | cut -d "|" -f1`
				}
				
				sleep ${DELAY_TIME}
			done 
		done 
	
	elif [[ $1 = "%LINUX%" ]]; then
		
		tput bold
		echo -e "\t\t\t Versions of Linux"
		tput sgr0
				
		for (( pass=0; pass<3; pass++ ))
		do 
			if [[ $pass -eq 0 ]]; then
				ADJUST_BY=0
				X_CURSOR_POS=2
				Y_CURSOR_POS=3
			elif [[ $pass -eq 1 ]]; then
				ADJUST_BY=10
				X_CURSOR_POS=25
				Y_CURSOR_POS=3
			else
				ADJUST_BY=20
				X_CURSOR_POS=48
				Y_CURSOR_POS=3
			fi 			
			
			for (( index=0; index<10; index++ ))
			do
				tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
				printf "%d) %s" $(( index + ADJUST_BY )) `echo ${ARR_LINUX[$(( index + ADJUST_BY ))]} | cut -d "|" -f1`
				
				LOOP_AT_28_COND=$(( index + ADJUST_BY )) ##Test when loop index gets to 28
				
				[[ ${LOOP_AT_28_COND} -eq 28 ]] && break
				
				sleep ${DELAY_TIME}
			done 			
		done 
		
	elif [[ $1 = "%SOLARIS%" ]]; then
		tput bold
		echo -e "\t\t\t Versions of Solaris"
		tput sgr0		
		
		X_CURSOR_POS=2
		Y_CURSOR_POS=3
		
		for (( index=0; index<5; index++ ))
		do 
			tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
			printf "%d) %s" ${index} `echo ${ARR_SOLARIS[${index}]} | cut -d "|" -f1`			
			
			sleep ${DELAY_TIME}
		done
		
	elif [[ $1 = "%BSD%" ]]; then
		tput bold
		echo -e "\t\t\t Versions of BSD"
		tput sgr0		
		
		X_CURSOR_POS=2
		Y_CURSOR_POS=3
		
		for (( index=0; index<6; index++ ))
		do 
			tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
			printf "%d) %s" ${index} `echo ${ARR_BSD[${index}]} | cut -d "|" -f1`			
			
			sleep ${DELAY_TIME}
		done
				
	elif [[ $1 = "%IBMOS%" ]]; then
		tput bold
		echo -e "\t\t\t Versions of IBM OS/2"
		tput sgr0		
		
		X_CURSOR_POS=2
		Y_CURSOR_POS=3
		
		for (( index=0; index<6; index++ ))
		do 
			tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
			printf "%d) %s" ${index} `echo ${ARR_IBMOS2[${index}]} | cut -d "|" -f1`			
		done
						
	elif [[ $1 = "%MACOSX%" ]]; then
		tput bold
		echo -e "\t\t\t Versions of MacOS X"
		tput sgr0		
		
		X_CURSOR_POS=2
		Y_CURSOR_POS=3
		
		for (( index=0; index<9; index++ ))
		do 
			tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
			printf "%d) %s" ${index} `echo ${ARR_MACOSX[${index}]} | cut -d "|" -f1`			
			
			sleep ${DELAY_TIME}
		done
		
	elif [[ $1 = "%OTHEROS%" ]]; then
		tput bold
		echo -e "\t\t\t Versions of Other OS"
		tput sgr0		
		
		X_CURSOR_POS=2
		Y_CURSOR_POS=3
		
		for (( index=0; index<7; index++ ))
		do 
			tput cup $(( Y_CURSOR_POS + index )) ${X_CURSOR_POS}
			printf "%d) %s" ${index} `echo ${ARR_OTHEROS[${index}]} | cut -d "|" -f1`			
			
			sleep ${DELAY_TIME}
		done
									
	fi
	
	echo -e "\n"
}

tput bold
echo -e "\t\t\tSelect OS Type"
PS3="Choose type: "
tput sgr0

select option in "${ARR_OS_TYPE[@]}"
do 
	case $option in 
	
########################################################
#				Microsoft Windows Versions			   #
########################################################	
		"Microsoft Windows") 
			_display_Ostype_ %WINDOWS% 
			
			printf "\t\t%s: " "Choose version[Windows3.1]"
			read -n 2 version
			echo 
			
			case $version in 
					
				1|01) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[1]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[1]} | cut -d "|" -f3`				
				;;
				2|02) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[2]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[2]} | cut -d "|" -f3`				
				;;
				3|03) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[3]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[3]} | cut -d "|" -f3`				
				;;
				4|04) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[4]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[4]} | cut -d "|" -f3`				
				;;
				5|05) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[5]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[5]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[5]} | cut -d "|" -f3`				
				;;
				6|06) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[6]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[6]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[6]} | cut -d "|" -f3`				
				;;
				7|07) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[7]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f3`				
				;;
				8|08) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[8]} | cut -d "|" -f3`				
				;;
				9|09) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[9]} | cut -d "|" -f3`				
				;;
				10) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[10]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[10]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[10]} | cut -d "|" -f3`				
				;;
				11) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[11]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[11]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[11]} | cut -d "|" -f3`				
				;;
				12) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[12]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[12]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[12]} | cut -d "|" -f3`				
				;;
				13) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[13]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[13]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[13]} | cut -d "|" -f3`				
				;;
				14) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[14]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[14]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[14]} | cut -d "|" -f3`				
				;;
				15) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[15]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[15]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[15]} | cut -d "|" -f3`				
				;;
				16) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[16]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[16]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[16]} | cut -d "|" -f3`				
				;;
				17) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[17]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[17]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[17]} | cut -d "|" -f3`				
				;;
				18) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[18]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[18]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[18]} | cut -d "|" -f3`				
				;;
				19) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[19]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[19]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[19]} | cut -d "|" -f3`				
				;;
				20) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[20]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[20]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[20]} | cut -d "|" -f3`				
				;;
				21) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[21]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[21]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[21]} | cut -d "|" -f3`				
				;;
				22) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[22]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[22]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[22]} | cut -d "|" -f3`				
				;;
				23) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[23]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[23]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[23]} | cut -d "|" -f3`				
				;;
				24) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[24]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[24]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[24]} | cut -d "|" -f3`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_MICROSOFT_WINDOWS[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[0]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MICROSOFT_WINDOWS[0]} | cut -d "|" -f3`
				;;				
			esac
			
			break
		;;

########################################################
#				Linux Versions						   #
########################################################
		"Linux") 
		
			_display_Ostype_ %LINUX% 
			printf "\n\t\t%s: " "Choose version[Linux2.2]"
			read -n 2 version
			echo 
			
			case $version in 
					
				1|01) 
					OS_VERSION=`echo ${ARR_LINUX[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[1]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[1]} | cut -d "|" -f3`				
				;;
				2|02) 
					OS_VERSION=`echo ${ARR_LINUX[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[2]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[2]} | cut -d "|" -f3`				
				;;
				3|03) 
					OS_VERSION=`echo ${ARR_LINUX[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[3]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[3]} | cut -d "|" -f3`				
				;;
				4|04) 
					OS_VERSION=`echo ${ARR_LINUX[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[4]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[4]} | cut -d "|" -f3`				
				;;
				5|05) 
					OS_VERSION=`echo ${ARR_LINUX[5]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[5]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[5]} | cut -d "|" -f3`				
				;;
				6|06) 
					OS_VERSION=`echo ${ARR_LINUX[6]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[6]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[6]} | cut -d "|" -f3`				
				;;
				7|07) 
					OS_VERSION=`echo ${ARR_LINUX[7]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[7]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[7]} | cut -d "|" -f3`				
				;;
				8|08) 
					OS_VERSION=`echo ${ARR_LINUX[8]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[8]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[8]} | cut -d "|" -f3`				
				;;
				9|09) 
					OS_VERSION=`echo ${ARR_LINUX[9]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[9]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[9]} | cut -d "|" -f3`				
				;;
				10) 
					OS_VERSION=`echo ${ARR_LINUX[10]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[10]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[10]} | cut -d "|" -f3`				
				;;
				11) 
					OS_VERSION=`echo ${ARR_LINUX[11]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[11]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[11]} | cut -d "|" -f3`				
				;;
				12) 
					OS_VERSION=`echo ${ARR_LINUX[12]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[12]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[12]} | cut -d "|" -f3`				
				;;
				13) 
					OS_VERSION=`echo ${ARR_LINUX[13]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[13]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[13]} | cut -d "|" -f3`				
				;;
				14) 
					OS_VERSION=`echo ${ARR_LINUX[14]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[14]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[14]} | cut -d "|" -f3`				
				;;
				15) 
					OS_VERSION=`echo ${ARR_LINUX[15]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[15]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[15]} | cut -d "|" -f3`				
				;;
				16) 
					OS_VERSION=`echo ${ARR_LINUX[16]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[16]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[16]} | cut -d "|" -f3`				
				;;
				17) 
					OS_VERSION=`echo ${ARR_LINUX[17]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[17]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[17]} | cut -d "|" -f3`				
				;;
				18) 
					OS_VERSION=`echo ${ARR_LINUX[18]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[18]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[18]} | cut -d "|" -f3`				
				;;
				19) 
					OS_VERSION=`echo ${ARR_LINUX[19]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[19]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[19]} | cut -d "|" -f3`				
				;;
				20) 
					OS_VERSION=`echo ${ARR_LINUX[20]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[20]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[20]} | cut -d "|" -f3`				
				;;
				21) 
					OS_VERSION=`echo ${ARR_LINUX[21]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[21]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[21]} | cut -d "|" -f3`				
				;;
				22) 
					OS_VERSION=`echo ${ARR_LINUX[22]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[22]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[22]} | cut -d "|" -f3`				
				;;
				23) 
					OS_VERSION=`echo ${ARR_LINUX[23]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[23]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[23]} | cut -d "|" -f3`				
				;;
				24) 
					OS_VERSION=`echo ${ARR_LINUX[24]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[24]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[24]} | cut -d "|" -f3`				
				;;
				25) 
					OS_VERSION=`echo ${ARR_LINUX[25]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[25]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[25]} | cut -d "|" -f3`				
				;;
				26) 
					OS_VERSION=`echo ${ARR_LINUX[26]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[26]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[26]} | cut -d "|" -f3`				
				;;
				27) 
					OS_VERSION=`echo ${ARR_LINUX[27]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[27]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[27]} | cut -d "|" -f3`				
				;;
				28) 
					OS_VERSION=`echo ${ARR_LINUX[28]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[28]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[28]} | cut -d "|" -f3`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_LINUX[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[0]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[0]} | cut -d "|" -f3`
				;;				
			esac			
			
			break
			
		;; 

########################################################
#				Solaris Versions					   #
########################################################
		"Solaris") 
		
			_display_Ostype_ %SOLARIS% 
			printf "\t\t%s: " "Choose version[Oracle_Solaris10-5/09AndEarlier[32bit]]"
			read -n 1 version
			echo 
			
			case $version in 
				
				1) 
					OS_VERSION=`echo ${ARR_LINUX[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[1]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[1]} | cut -d "|" -f3`				
				;;
				2) 
					OS_VERSION=`echo ${ARR_LINUX[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[2]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[2]} | cut -d "|" -f3`				
				;;
				3) 
					OS_VERSION=`echo ${ARR_LINUX[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[3]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[3]} | cut -d "|" -f3`				
				;;
				4) 
					OS_VERSION=`echo ${ARR_LINUX[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[4]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[4]} | cut -d "|" -f3`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_LINUX[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_LINUX[0]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_LINUX[0]} | cut -d "|" -f3`
				;;
			esac			
			
			break
			
		;; 
		
		
########################################################
#					BSD Versions					   #
########################################################
		"BSD") 
		
			_display_Ostype_ %BSD% 
			printf "\t\t%s: " "Choose version[FreeBSD[32bit]]"
			read -n 1 version
			echo 
			
			case $version in 
				
				1) 
					OS_VERSION=`echo ${ARR_BSD[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_BSD[1]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_BSD[1]} | cut -d "|" -f3`				
				;;
				2) 
					OS_VERSION=`echo ${ARR_BSD[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_BSD[2]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_BSD[2]} | cut -d "|" -f3`				
				;;
				3) 
					OS_VERSION=`echo ${ARR_BSD[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_BSD[3]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_BSD[3]} | cut -d "|" -f3`				
				;;
				4) 
					OS_VERSION=`echo ${ARR_BSD[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_BSD[4]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_BSD[4]} | cut -d "|" -f3`				
				;;
				5) 
					OS_VERSION=`echo ${ARR_BSD[5]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_BSD[5]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_BSD[5]} | cut -d "|" -f3`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_BSD[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_BSD[0]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_BSD[0]} | cut -d "|" -f3`
				;;
			esac			
			
			break
			
		;; 
		
########################################################
#				IBM OS 2 Versions					   #
########################################################		
		"IBM OS/2") 
		
			_display_Ostype_ %IBMOS% 
			printf "\t\t%s: " "Choose version[OS/2_Warp_3]"
			read -n 1 version
			echo 
			
			case $version in 
					
				1) 
					OS_VERSION=`echo ${ARR_IBMOS2[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[1]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[1]} | cut -d "|" -f3`				
				;;
				2) 
					OS_VERSION=`echo ${ARR_IBMOS2[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[2]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[2]} | cut -d "|" -f3`				
				;;
				3) 
					OS_VERSION=`echo ${ARR_IBMOS2[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[3]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[3]} | cut -d "|" -f3`				
				;;
				4) 
					OS_VERSION=`echo ${ARR_IBMOS2[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[4]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[4]} | cut -d "|" -f3`				
				;;
				5) 
					OS_VERSION=`echo ${ARR_IBMOS2[5]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[5]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[5]} | cut -d "|" -f3`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_IBMOS2[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_IBMOS2[0]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_IBMOS2[0]} | cut -d "|" -f3`
				;;				
			esac			
			
			break
			
		;;
		
########################################################
#				Mac OS X Versions					   #
########################################################		
		"Mac OS X") 
		
			_display_Ostype_ %MACOSX% 
			printf "\t\t%s: " "Choose version[Mac_OSX[32bit]]"
			read -n 1 version
			echo 
			
			case $version in 
				
				1) 
					OS_VERSION=`echo ${ARR_MACOSX[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[1]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[1]} | cut -d "|" -f3`				
				;;
				2) 
					OS_VERSION=`echo ${ARR_MACOSX[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[2]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[2]} | cut -d "|" -f3`				
				;;
				3) 
					OS_VERSION=`echo ${ARR_MACOSX[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[3]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[3]} | cut -d "|" -f3`				
				;;
				4) 
					OS_VERSION=`echo ${ARR_MACOSX[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[4]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[4]} | cut -d "|" -f3`				
				;;
				5) 
					OS_VERSION=`echo ${ARR_MACOSX[5]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[5]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[5]} | cut -d "|" -f3`				
				;;
				6) 
					OS_VERSION=`echo ${ARR_MACOSX[6]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[6]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[6]} | cut -d "|" -f3`				
				;;
				7) 
					OS_VERSION=`echo ${ARR_MACOSX[7]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[7]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[7]} | cut -d "|" -f3`				
				;;
				8) 
					OS_VERSION=`echo ${ARR_MACOSX[8]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[8]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[8]} | cut -d "|" -f3`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_MACOSX[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_MACOSX[0]} | cut -d "|" -f2`
					RECOM_DISK_SIZE=`echo ${ARR_MACOSX[0]} | cut -d "|" -f3`
				;;				
			esac			
			
			break
			
		;;
		
########################################################
#					Other Versions					   #
########################################################		
		"Other") 
		
			_display_Ostype_ %OTHEROS% 
			printf "\t\t%s: " "Choose version[DOS]"
			read -n 1 version
			echo 
			
			case $version in 
					
				1) 
					OS_VERSION=`echo ${ARR_OTHEROS[1]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[1]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[1]} | cut -d "|" -f1`				
				;;
				2) 
					OS_VERSION=`echo ${ARR_OTHEROS[2]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[2]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[2]} | cut -d "|" -f1`				
				;;
				3) 
					OS_VERSION=`echo ${ARR_OTHEROS[3]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[3]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[3]} | cut -d "|" -f1`				
				;;
				4) 
					OS_VERSION=`echo ${ARR_OTHEROS[4]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[4]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[4]} | cut -d "|" -f1`				
				;;
				5) 
					OS_VERSION=`echo ${ARR_OTHEROS[5]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[5]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[5]} | cut -d "|" -f1`				
				;;
				6) 
					OS_VERSION=`echo ${ARR_OTHEROS[6]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[6]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[6]} | cut -d "|" -f1`				
				;;
				*) 
					OS_VERSION=`echo ${ARR_OTHEROS[0]} | cut -d "|" -f1`
					RECOM_RAM_SIZE=`echo ${ARR_OTHEROS[${index}]} | cut -d "|" -f1`
					RECOM_DISK_SIZE=`echo ${ARR_OTHEROS[${index}]} | cut -d "|" -f1`				
				;;				
			esac			
			
			break
			
		;;
		
		"Quit") break ;;
		
	esac
	
done
