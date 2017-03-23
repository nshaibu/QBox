#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Manage The Settings Of Peripherals
#-------------------------------------------------------------------------------------------
# Check_pkg_install is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your option) 
# any later version.

# Check_pkg_install is distributed in the hopes that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#===========================================================================================

##globals
HD_IMG_DIR=$HOME/.img_qemubox
QBOX_DIR=/usr/local/bin/QBox

VNC_DISPLAY=3`${QBOX_DIR}/bin/qemubox_random 15`00
VNC_PORT=`expr ${VNC_DISPLAY} + 5900`
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox
PYTHON_LOC=${QBOX_DIR}/python3
QEMU_PATH=

IF_ADDR=`python ${PYTHON_LOC}/netiface_deter.py`
[ "${IF_ADDR}" = "" ] && IF_ADDR="localhost"

function yes_no()
{
	read -n 1 resp
	case "$resp" in 
		[Yy]|[Yy][Ee][Ss]) echo 0;;
		*) echo 1 ;;
	esac
}

##Search for iso files at home directory
function Search_iso_file()
{
	printf "%s\n" "[2]Enter the name of the OS iso file[Enter]"
	read QEMU_PATH
	
	while [ -z ${QEMU_PATH} ]
	do
		echo "   ->The system will check for iso files in [${HOME}]"
		echo "   ->checking ... " && echo
		for i in $(find ${HOME} -depth -type f -a -name "*.iso" -print 2>>/dev/null)
		do 
			
			echo "     ->Found $(basename $i)" && sleep 1
		done
		echo
		[ "$i" = "" ] && break 
		
		printf "%s" "[3]Choose an iso from above "
		read QEMU_PATH
	done
	
	TEMP_PATH=`find ${HOME} -depth -name ${QEMU_PATH} -print 2>/dev/null`
	
	if [[ -n ${TEMP_PATH} ]]; then
			
		echo "   ->Searching [${HOME}] for ${QEMU_PATH}..." && sleep 1
		echo "   ->FOUND @ [${TEMP_PATH})] " && sleep 1
		echo "   ->Setting path to [${TEMP_PATH}]" && sleep 1
		QEMU_PATH=${TEMP_PATH}
	else
		echo "  ->ISO file not found in the [${HOME}] "
		echo "  ->Copy the ISO file to [${HOME}] or It's sub-directory "
		exit 1
	fi	
}



function boot_func(){
		
		OLDIFS=$IFS
		IFS="-"
		set $1
		
		##Generates random name and location for the virtual harddisk
		HD_IMG=${HOME}/.img_qemubox/qbox$3box_$rand${ra}.img
		HD_BI_IMG="-hda ${HD_IMG}"
			
			
			IFS=$OLDIFS
			printf "%s\n" "[1]Creating new disk image..." && sleep 1 & echo
			
			if [[ ${DSKIMG} != "raw" ]]; then
				${QEMU_DSKIMG_CREATOR} create -f ${DSKIMG} ${HD_IMG} ${DSKSIZE} 2>${TEMP_FOLDER}/.error.tt 
			else 
				${QEMU_DSKIMG_CREATOR} create -f ${DSKIMG} -o size=${DSKSIZE} ${HD_IMG} 2>${TEMP_FOLDER}/.error.tt 
			fi 
			
			##system errror logger
			logger_logging
			
			printf "%s\n" "[2]Installing..." && sleep 1
			
			${QEMU} ${VM_NAME} ${NUM_CPU} ${RAM_SIZE} ${NET_CON} ${QEMU_GRAPH} ${QEMU_SOUND} ${QEMU_USB} \
			${HD_BI_IMG} ${BOOT_DEV} ${KVM_ENABLE} ${BOOT_ORDER} 2>${TEMP_FOLDER}/.error.tt
			
			##system Error logger
			logger_logging
				
				
			printf "%s" "[3]Do you want to save this VM[yes/no]? "
			rezult=$(yes_no)
			if [ $rezult -eq 0 ]; then
				##Generates boot files containing all the configurations
				if [ -f ${TEMP_FOLDER}/.test_tap_exit.tt ]; then ##if file exist then remove ${NET_CON}
					if ! [ -d ${TAP_DIR} ]; then
						mkdir ${TAP_DIR}
					fi
					
					##Stop bridging and tap interface
					stop_tap_if
					NET_CON=""
					
					##Generates boot file naming it with the name of the virtual hard disk already created
					bash ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
					%${VGA} %${DISPLAY} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${HOSTNAME0} %${TAP0} \
					%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
					%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${HOSTNAME1} %${TAP1} \
					%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
					%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${HOSTNAME2} %${TAP2} \
					%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
					%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${HOSTNAME3} %${TAP3} \
					%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
					%${MCAST3} %${SMB_SERVER} %${REDIRECT} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} % % %${QEMU_KEYBOARD} \
					%${QEMU_FULLSCREEN} % %${SNAP_OT} % % %
					
					rm -f ${TEMP_FOLDER}/.test_tap_exit.tt 2>/dev/null
					
				else
					##generate boot file
					bash ${QBOX_DIR}/bash_s/qemu-bootfile-generator.sh ${HD_IMG} ${QEMU} %${VM_NAME} %${CPU} %${CORE} %${RAM_SIZE} \
					%${VGA} %${DISPLAY} %${NETWORK0} %${VLAN0} %${MAC0} %${MODEL0} %${USER0} %${VLAN_USER0} %${HOSTNAME0} %${TAP0} \
					%${VLAN_TAP0} %${FD_TAP0} %${IFNAME0} %${SCRIPT0} %${SOCKET0} %${VLAN_SOCKET0} %${FD_SOCKET0} %${LISTEN0} %${CONNECT0} \
					%${MCAST0} %${NETWORK1} %${VLAN1} %${MAC1} %${MODEL1} %${USER1} %${VLAN_USER1} %${HOSTNAME1} %${TAP1} \
					%${VLAN_TAP1} %${FD_TAP1} %${IFNAME1} %${SCRIPT1} %${SOCKET1} %${VLAN_SOCKET1} %${FD_SOCKET1} %${LISTEN1} %${CONNECT1} \
					%${MCAST1} %${NETWORK2} %${VLAN2} %${MAC2} %${MODEL2} %${USER2} %${VLAN_USER2} %${HOSTNAME2} %${TAP2} \
					%${VLAN_TAP2} %${FD_TAP2} %${IFNAME2} %${SCRIPT2} %${SOCKET2} %${VLAN_SOCKET2} %${FD_SOCKET2} %${LISTEN2} %${CONNECT2} \
					%${MCAST2} %${NETWORK3} %${VLAN3} %${MAC3} %${MODEL3} %${USER3} %${VLAN_USER3} %${HOSTNAME3} %${TAP3} \
					%${VLAN_TAP3} %${FD_TAP3} %${IFNAME3} %${SCRIPT3} %${SOCKET3} %${VLAN_SOCKET3} %${FD_SOCKET3} %${LISTEN3} %${CONNECT3} \
					%${MCAST3} %${SMB_SERVER} %${REDIRECT} %${QEMU_SOUND} %${QEMU_USB} %${HD_BI_IMG} %${KVM_ENABLE} % % %${QEMU_KEYBOARD} \
					%${QEMU_FULLSCREEN} % %${SNAP_OT} % % %
				fi
			else
				rm -f ${HD_IMG}
			fi 
} 

#############################################
#			Configure Sound					#
#############################################
if [[ $1 = "%SOUND%" ]]; then

	echo
	printf "%s\n" "[1]Enter the name of sound card to emulate[ENTER]"
	printf "%s\n" "   Options:[1 ---------> Creative SoundBlaster 16 sound card    ]" \
				  "           [2 ---------> ENSONIQ AudioPCI ES1370 sound card     ]" \
				  "           [3 ---------> Intel HD Audio Controller and HDA codec]" \
				  "           [4 ---------> Disable Sound                          ]"
	read -n 1 sd

	case "$sd" in 
		1) SND="-soundhw sb16" ;;
		2) SND="-soundhw es1370" ;;
		3) SND="-soundhw hda" ;;
		*) SND="" ;;
	esac
	
	QEMU_SOUND=${SND}


#############################################
#			Configure Display to use		#
#############################################
elif [[ $1 = "%DISPLAY%" ]]; then

	echo
	printf "%s\n" "[1]Choose a Display for the VM[ENTER]"
	printf "%s\n" "   Options:[1 ---------> Display video output via curses]" \
				  "           [2 ---------> Display video output via SDL   ]" \
				  "           [3 ---------> Display video output via VNC   ]"
	read sd

	case "$sd" in 
		3)
			DISPLAY_="-display vnc=:${VNC_DISPLAY}"
			printf "%s\n" "To veiw your vm.Enter vncviewer ${IF_ADDR}:${VNC_PORT}"
		;;
		1) DISPLAY_="-display curses" ;;
		*) DISPLAY_="-display sdl" ;;
	esac
	
	printf "%s\n" "[2]Choose a Video Card for the VM[ENTER]"
	printf "%s\n" "   Options:[1 ---------> Cirrus Logic GD5446 Video card             ]" \
				  "           [2 ---------> Standard VGA card with Bochs VBE extensions]"
	read -n 1 vcard
	
	case "$vcard" in 
		2) VGA="-vga std" ;;
		*) VGA="-vga cirrus" ;;
	esac
	
	QEMU_GRAPH="${VGA} ${DSPY}" 

#############################################
#	Configure the number of cpu to use		#
#############################################
elif [[ $1 = "%CPU%" ]]; then
	
	printf "%s" "[5]Enter the number of cpu cores to emulate[Enter] "
	read -n 1 numcore
	echo 
	
	CPU="-cpu host"
	case $numcore in 
		4|3|2) CORE="-smp $numcore" ;;
		*) CORE="-smp 1" ;;
	esac
	
	NUM_CPU="${CPU} ${CORE}"
	
	
elif [[ $1 = "%FULLSCREEN%" ]]; then
	
	printf "%s\n" "[4]Enable VM to start in fullscreen[CTL+ALT+f-->window mode][yes/NO]"
	result=$(yes_no)
	
	[ $result -eq 0 ] && FULLS="-full-screen"
	QEMU_FULLSCREEN=${FULLS}
	
	
elif [[ $1 = "%USB%" ]]; then
	
	printf "%s\n" "[5]Choose a Pointing device for the VM[ENTER]"
	printf "%s\n" "   Options:[1 -------> Virtual Mouse                    ]" \
				  "           [2 -------> Pointer device like a touchscreen]" \
				  "           [3 -------> Default                          ]"
				  
	read -n 1 usb 
	case "$usb" in
		1) USBD="-usbdevice mouse" ;;
		2) USBD="-usbdevice tablet" ;;
		*) ;;
	esac
	
	QEMU_USB=${USBD} 

#############################################
#				keyboard layout				#
#############################################
elif [[ $1 = "%KEYBOARD%" ]]; then
	
	printf "%s\n" "[3]Specify the keyboard layout to use[DEFAULT]"
	printf "%s\n" "   Options:[ar  de-ch  es  fo] [fr-ca  hu  ja  mk]" \
				  "           [no  pt-br  sv    ] [da  en-gb  et  fr]" \
				  "           [fr-ch  is  lt  nl] [pl  ru  th  tr de]" \
				  "           [en-us fi fr-be hr] [it lv nl-be pt sl]"
	read lan
	
	case "$lan" in 
		ar|de-ch|es|fo|fr-ca|hu|ja|mk) KYBD="-k $lan" ;;
		no|pt-br|sv|da|en-gb|et|fr) KYBD="-k $lan";;
		fr-ch|is|lt|nl|pl|ru|th|tr|de) KYBD="-k $lan" ;;
		en-us|fi|fr-be|hr|it|lv|nl-be|pt|sl) KYBD="-k $lan" ;;
		*) KYBD="-k en-us" ;;
	esac
	
	QEMU_KEYBOARD=${KYBD} 

#############################################
#		Enable harddisk snapshot mode		#
#############################################
elif [[ $1 = "%SNAPSHOT%" ]]; then
	
	printf "%s" "[3]Enable Snapshot Mode[yes/NO] "
	re=`yes_no`
	
	[ $re -eq 0 ] && SNAP="-snapshot"
	
	SNAP_OT=${SNAP}
	echo

#############################################
#				Architecture				#
#############################################
elif [[ $1 = "%ARCHITECTURE%" ]]; then
	echo
	
	[ "$2" = "" ] && {
			printf "%s\n" "   Options:[1 -------------------->PC,intel-8086(64bit) ]"		\
						  "           [2 -------------------->PC,ARM,little endian ]"				\
						  "           [3 -------------------->PC,ARM,big endian    ]"				\
						  "           [4 -------------------->PC,intel-8086(32bit) ]"		\
						  "           [5 -------------------->PC,PowerPC(32bit)    ]"		\
						  "           [6 -------------------->PC,PowerPC(64bit)    ]"		\
						  "           [7 -------------------->PC,SPARC(64bit)      ]"		\
						  "           [8 -------------------->PC,SPARC(32bit)      ]"		\
						  "           [9 -------------------->PC,MIPS,little endian]"		\
						  "           [10-------------------->PC,MIPS,big endian   ]"		
			printf "%s" "What Computer architecture do you want to emulate "
			read -n 2 qeoption
	
			echo
	
			case "$qeoption" in 
				4) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-i386`
					BOOT_ORDER="-boot order=d"
					KVM_ENABLE="-enable-kvm"
				 ;;
				1) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-x86_64`
					BOOT_ORDER="-boot order=d"
					KVM_ENABLE="-enable-kvm"
				;;
				2) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-arm` 
					BOOT_ORDER="-boot order=d"
				;;
				3) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-armeb` 
					BOOT_ORDER="-boot order=d"
				;;
				5) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc` 
					BOOT_ORDER="-boot order=d"
				;;
				6) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc64` 
					BOOT_ORDER="-boot order=d"
				;;
				8) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc` 
					BOOT_ORDER="-boot order=d"
				;;
				7) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc64` 
					BOOT_ORDER="-boot order=d"
				;;
				10) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mips` 
					BOOT_ORDER="-boot order=d"
				;;
				9) 
					QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mipsel` 
					BOOT_ORDER="-boot order=d"
				;;
				*)  
					printf "%s\n" "---->Architecture option is defaulting to x86_64"
					printf "%s" "---->Do you want to enter the architecture name?[yes/no] "
					read val
					case "$val" in 
						YES|Yes|YeS|y|Y|yEs|YEs|yES) 
							printf "%s\n" "---->Enter the name in the format[qemu-system-architecture-name]"
							read QEMU
							;;
						*)
							QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-x86_64` 
							BOOT_ORDER="-boot order=d"
							KVM_ENABLE="-enable-kvm"
						;;
					esac
			esac
	} || {
	
	#################################################
	#	Architecture Display using Dialog utility	#
	#################################################
			case $2 in 
				1) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-i386` ;;
				2) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-x86_64` ;;
				3) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-arm` ;;
				4) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-armeb` ;;
				5) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc` ;;
				6) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-ppc64` ;;
				7) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc` ;;
				8) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-sparc64` ;;
				9) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mipsel` ;;
				10) QEMU=`$QBOX_DIR/bash_s/check_pkg_install.sh %CHECK_RUN% qemu-system-mips` ;;
			esac
	}
	
elif [[ $1 = "%BOOT_DEVICE%" ]]; then
	
	printf "%s\n" "[1]Choose the boot media to used[ENTER]"
	printf "%s\n" "   Options:[1 -------------> use CD-ROM ]" \
	              "           [2 -------------> use Floppy ]" 	
	read -n 1 device
	
	case $device in 
		2) 
			BOOT_ORDER="-boot order=a"
			read -n 2 -p "Do you want to use host floppy device?[y/[N]] " dev 
			case $dev in 
				Y|y) BOOT_DEV="-fda /dev/fd0" ;;
				*) 
					Search_iso_file
					BOOT_DEV="-fda ${QEMU_PATH}"
				;;
			esac 		
		;;	
		*) 
			BOOT_ORDER="-boot order=d"
			read -n 2 -p "Do you want to use host cdrom device?[y/[N]] " dev 
			case $dev in 
				Y|y) BOOT_DEV="-cdrom /dev/cdrom" ;;
				*) 
					Search_iso_file
					BOOT_DEV="-cdrom ${QEMU_PATH}"
				;;
			esac 		
		;;
	esac
fi 
