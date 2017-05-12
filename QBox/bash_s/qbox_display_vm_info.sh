#!/bin/bash

#===========================================================================================
# Copyright (C) 2016 Nafiu Shaibu.
# Purpose: Display Information on Created VM
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
: ${LIB_DIR:=/usr/local/bin/QBox/include_dir}

. ${LIB_DIR}/import '<init.h>'

INFO_FILE_=$1
DESCRIPTION=${QDB_FOLDER}/description.qdb

declare TIME_DELAY=0.0155

##ARRAY CONTAINER
declare -a ARR_CONTAINER

declare -a arr_vm_general=("#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" \
						"G" "E" "N" "E" "R" "A" "L" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#")
declare -a arr_vm_system_=("#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" \
						"S" "Y" "S" "T" "E" "M" " " "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#")
declare -a arr_vm_audios_=("#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" \
						"A" "U" "D" "I" "O" " " " " "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#")
declare -a arr_vm_display=("#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" \
						"D" "I" "S" "P" "L" "A" "Y" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#")
declare -a arr_vm_network=("#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" \
						"N" "E" "T" "W" "O" "R" "K" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#" "#")

function move_cursor(){
	##first half
	for ((i=0; i<${#arr_vm_audios_[@]}; i++)); do 
		
		if [[ "$2" = "%GENERAL%" ]]; then
			
			tput cup $1 $i
			tput bold
			
			printf "%c" ${arr_vm_general[$i]}
			sleep ${TIME_DELAY}
			
		elif [[ "$2" = "%SYSTEM%" ]]; then
			
			tput cup $1 $i
			tput bold
			
			printf "%c" ${arr_vm_system_[$i]}
			sleep ${TIME_DELAY}
			
		elif [[ "$2" = "%AUDIO%" ]]; then
			
			tput cup $1 $i
			tput bold
			
			printf "%c" ${arr_vm_audios_[$i]}
			sleep ${TIME_DELAY}
			
		elif [[ "$2" = "%DISPLAY%" ]]; then
			tput cup $1 $i
			tput bold
			
			printf "%c" ${arr_vm_display[$i]}
			sleep ${TIME_DELAY}
			
		elif [[ "$2" = "%NETWORK%" ]]; then
			tput cup $1 $i
			tput bold
			
			printf "%c" ${arr_vm_network[$i]}
			sleep ${TIME_DELAY}
		fi 
		
	done
	
}

function  print_scr(){
	
	move_cursor $1 $2
	
	echo
	
	for index in ${ARR_CONTAINER[@]}; do 
		echo ${index}
		tput sgr0
	done
}


#################################
#		SETTIGS GENERAL			#
#################################
_name=$(gawk -F "|" -v var="vm_name" '$1 ~ var {print $2}' ${INFO_FILE_} | sed s/-//g)
			
#-----------------------------------PROCESSING DATA----------------------------------------0
_name=${_name:5}
descrip=`gawk -F "|" -v var=${_name} '$1 ~ var {print $2}' ${DESCRIPTION}`

ARR_CONTAINER=("Name:$_name" "Operating_System:${descrip}")

#PRINT TO STDOUT	    
print_scr 0 %GENERAL%
			
#################################
#		SETINGS SYSTEM			#
#################################
_arch_=$(gawk -F "|" -v var="archtype" '$1 ~ var {print $2}' ${INFO_FILE_})
_numcpu_=$(gawk -F "|" -v var="smp" '$1 ~ var {print $2}' ${INFO_FILE_})
_ram_=$(gawk -F "|" -v var="ram" '$1 ~ var {print $2}' ${INFO_FILE_})
_kvm_=`gawk -F "|" -v var="kvm" '$1 ~ var {print $2}' ${INFO_FILE_} `
			
##-----------------------------------PROCESSING DATA----------------------------------------
_arch_=`basename $_arch_ 2>/dev/null`
if [[ ${_arch_:5:4} = "syst" ]]; then
	_arch=${_arch_:12}
else
	_arch=${_arch_:5}
fi 

case "${_arch}" in 
	x86_64) _arch="PC,intel-8086[64bit]" ;;
	i386) _arch="PC,intel-8086[32bit]" ;;
	arm) _arch="ARM,little-endian" ;;
	armeb) _arch="ARM,big-endian" ;;
	ppc) _arch="PowerPC[32bit]" ;;
	ppc64) _arch="PowerPC[64bit]" ;;
	sparc) _arch="SPARC[32bit]" ;;
	sparc64) _arch="SPARC[64bit]" ;;
	mips) _arch="MIPS,big-endian" ;;
	mipsel) _arch="MIPS,little-endian" ;;
esac
#-------------------------------------------------------------------------------------------
if [[ -n "$_kvm_" ]]; then 
	_kvm_="Enabled"
else
	_kvm_="Disabled"
fi 
#-------------------------------------------------------------------------------------------
_numcpu_=${_numcpu_:5}
#-------------------------------------------------------------------------------------------
_ram_=${_ram_:3}

ARR_CONTAINER=("Architecture:$_arch" "Processors:$_numcpu_" "Ram_Size:$_ram_" "KVM:$_kvm_")

##-----------------------------------PRINT TO STDOUT----------------------------------------3
print_scr 3 %SYSTEM%
			
#################################		
#		SETINGS AUDIO			#
#################################
_snd_=$(gawk -F "|" -v var="audio" '$1 ~ var {print $2}' ${INFO_FILE_} )
			
			
##-----------------------------------PROCESSING DATA----------------------------------------
if [ -n "$_snd_" ]; then
	_enab_="Enabled"
	sndcard=${_snd_:9}
	
	case $sndcard in 
		sb16) snd="Creative-SoundBlaster-16-sound-card" ;;
		hda) snd="Intel-HD-Audio-Controller/HDA-codec" ;;
		es1370) snd="ENSONIQ-AudioPCI-ES1370-sound-card" ;;
	esac
	
else
	_enab_="Disabled"
fi 
	

	
ARR_CONTAINER=("Sound:$_enab_" "Sound_Card:$snd")
##-----------------------------------PRINT TO STDOUT----------------------------------------8
print_scr 8 %AUDIO%
		
#################################		
#		SETINGS DISPLAY			#
#################################
disptype=$(gawk -F "|" -v var="display" '$1 ~ var {print $2}' ${INFO_FILE_} )
dispcard=`gawk -F "|" -v var="vga" '$1 ~ var {print $2}' ${INFO_FILE_}`
kydlayout=$(gawk -F "|" -v var="keyboard" '$1 ~ var {print $2}' ${INFO_FILE_} )
fullscrn=$(gawk -F "|" -v var="fullscreen" '$1 ~ var {print $2}' ${INFO_FILE_} )
			
			
##-----------------------------------PROCESSING DATA----------------------------------------
if [[ ${dispcard:5} = "cirrus" ]]; then
	_disCd_="Cirrus-Logic-GD5446-Video-card"
else 
	_disCd_="Standard-VGA-card-with-Bochs-VBE-extensions"
fi 

case ${disptype:9:3} in
	sdl)_disp_="Via-SDL" ;;
	cur)_disp_="Via-Curses";;
	vnc) 
		_PORT_=${disptype:14}
		_disp_="Via-VNC-On-Port-${_PORT_}"
	;;
esac
 
#-------------------------------------------------------------------------------------------
_kydl_=`echo ${kydlayout:3} | awk '{print toupper($0)}'`
#-------------------------------------------------------------------------------------------
if [[ -n "${fullscrn}" ]]; then
	 _fullscr_="Enabled" 
else
	_fullscr_="Disabled" 
fi 

ARR_CONTAINER=("Display:$_disp_" "Display_Card:$_disCd_" "Keyboad:$_kydl_" "Fullscreen:$_fullscr_")

##-----------------------------------PRINT TO STDOUT----------------------------------------11
print_scr 11 %DISPLAY% 
		
#################################		
#		SETINGS NETWORK			#
#################################
_netty_=$(gawk -F "|" -v var="model0" '$1 ~ var {print $2}' ${INFO_FILE_})
			
			
##-----------------------------------PROCESSING DATA----------------------------------------
_netdev_=`echo ${_netty_:15} | cut -d, -f1`
_netty_=`echo ${_netty_:$(( ${#_netdev_} + 53 ))} | cut -d, -f1`

if [[ "$_netty_" = "user" ]]; then 
	_netty_="user-mode-network-stack"
else
	_netty_="TUN/TAP-interface"
fi

ARR_CONTAINER=("Network_Mode:$_netty_" "Network_Driver:$_netdev_")

##-----------------------------------PRINT TO STDOUT----------------------------------------16
print_scr 16 %NETWORK%
		

