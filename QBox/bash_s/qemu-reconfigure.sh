#!/bin/bash

HD_IMG_DIR=$HOME/.img_qemubox

##name=`cat ${HD_IMG_DIR}/.qbox_dir_code`
##[ "$name" = "${HOME}" ] && QBOX_DIR=${HOME}/QBox || QBOX_DIR=${HOME}/"`cat ${HD_IMG_DIR}/.qbox_dir_code`"/QBox ##contains qbox code
QBOX_DIR=/usr/local/bin/QBox

LOG_DIR=${HD_IMG_DIR}/logs_dir
BOOT_DIR=${HD_IMG_DIR}/.qemuboot ## contain boot files
PYTHON_LOC=${QBOX_DIR}/python3
VNC_DISPLAY=3`${QBOX_DIR}/bin/qemubox_random 15`00
VNC_PORT=`expr ${VNC_DISPLAY} + 5900`
TEMP_FOLDER=${HD_IMG_DIR}/.tmp_qbox


IF_ADDR=`python ${PYTHON_LOC}/netiface_deter.py`
[ -z "${IF_ADDR}" ] && IF_ADDR="localhost"

config_ram(){
	bootfile_loc=`cat ${TEMP_FOLDER}/reconf.tt`
	for i in $*
	do
		case $i in 
		-m) 
			echo -e "\nThe VM has ram size of $2"
			printf "%s " "Enter new ram size or [Enter] to exit"
			read ram
			if [ "$ram" != "" ];then
				python3 ${PYTHON_LOC}/reconfig.py ${bootfile_loc} "$2" "$ram"
				tput setaf 4
				echo "Ram size: $ram"
				tput sgr0
			fi
		;;
		*) shift ;;
		esac
	done
	
	return 0
}

config_sound(){
	bootfile_loc=`cat ${TEMP_FOLDER}/reconf.tt`
	for i in $*
	do
		case $i in 
		-soundhw) 
			echo -e "\nThe VM has $2 sound card"
			printf "%s" "---->Available drivers:[sb16,adlib,es1370,ac97,hda,all[DEFAULT] "
			read sd
			
			case "$sd" in 
				[Ss][Bb]16) SND="sb16";;
				[Aa][Dd][Ll][Ii][Bb]) SND="adlib";;
				[Ee][Ss]1370) SND="es1370";;
				[Aa][Cc]97) SND="ac97";;
				[Hh][Dd][Aa]) SND="hda";;
				*) SND="all" ;;
			esac
			
			python3 ${PYTHON_LOC}/reconfig.py ${bootfile_loc} "$2" "${SND}"
			tput setaf 4
			echo "Sound card: ${SND}"
			tput sgr0
		;;
		*) shift ;;
		esac
	done
	
	return 0
}

config_cpu(){
	bootfile_loc=`cat ${TEMP_FOLDER}/reconf.tt`
	for i in $*
	do
		case $i in 
		-smp) 
			echo -e "\nThe VM has $2 emulated cpus"
			printf "%s " "Enter number of cpus to emulate or [Enter] to exit"
			read cpu
			
			if [ "$cpu" != "" ]; then
					python3 ${PYTHON_LOC}/reconfig.py ${bootfile_loc} "$2" "$cpu"
					tput setaf 4
					echo "Number of cpus: $cpu"
					tput sgr0
			fi
		;;
		*) shift ;;
		esac
	done
	
	return 0
}

config_display(){
	bootfile_loc=`cat ${TEMP_FOLDER}/reconf.tt`
	for i in $*
	do
		case $i in 
		
		-display) 
			python3 ${PYTHON_LOC}/reconfig.py ${bootfile_loc} " $2" ""
			python3 ${PYTHON_LOC}/reconfig.py ${bootfile_loc} " $3" ""
		;;
		-vga) 
			printf "%s\n" "Enter display type to use or [Enter] to default"
			printf "%s" "   ->Available options:[cirrus, none, vnc, std[DEFAULT]] "
			read sd

			case "$sd" in 
				[Cc][Ii][Rr][Rr][Uu][Ss]) 
					SD="cirrus" 
					tput setaf 4
					echo "Display used: ${SD}"
					tput sgr0
				;;
				[Nn][Oo][Nn][Ee]) 
					SD="none"
					tput setaf 4
					echo "Display used: none"
					tput sgr0 
				;;
				[Vv][Nn][Cc])
					SD="std -display vnc=:${VNC_DISPLAY}" 
					##echo "-usbdevice tablet" 
					printf "%s\n" "To veiw your vm.Enter vncviewer ${IF_ADDR}:${VNC_PORT}"
					tput setaf 4
					echo "Display used: vnc"
					tput sgr0
				;;
				*) SD="std" 
					echo "Display used: std"
				;;
			esac
			
			python3 ${PYTHON_LOC}/reconfig.py ${bootfile_loc} "$2" "${SD}"
		;;
		*) shift ;;
		esac
	done
	
	return 0
}

qemu_reconfigure_func(){
	clear
	echo -e "\t\t\tQBox Reconfiguration Menu\n"
	echo -e "\t1. Reconfigure Display"
	echo -e "\t2. Reconfigure RAM Size"
	echo -e "\t3. Reconfigure number of CPU"
	echo -e "\t4. Reconfigure Sound System"
	echo -e "\t0. Back \u2b05 \n\n"
	
	echo -en "\t\tEnter Option: "
	read -n 1 opt
}

while true
do
	qemu_reconfigure_func
	
	case $opt in 
		1) 
			bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh l 2>/dev/null
			echo
			printf "%s" "Enter the name of the VM to reconfigure display[ENTER] "
			read name
			name=$(echo $name | awk '{print toupper($0)}') ##capitalise name
			if [ "$name" != "" ]; then
				bootvm=$(basename $(bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh s $name) 2>/dev/null)
				echo "${BOOT_DIR}/$bootvm">${TEMP_FOLDER}/reconf.tt
				config_display `cat ${BOOT_DIR}/$bootvm 2>/dev/null` 
				rm -f ${TEMP_FOLDER}/reconf.tt 2>/dev/null
			fi
		;;
		2) 
			bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh l 2>/dev/null
			echo
			printf "%s" "Enter the name of the VM to reconfigure RAM size[ENTER] "
			read name
			name=$(echo $name | awk '{print toupper($0)}') ##capitalise name
			if [ "$name" != "" ]; then
				bootvm=$(basename $(bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh s $name) 2>/dev/null)
				echo "${BOOT_DIR}/$bootvm">${TEMP_FOLDER}/reconf.tt
				config_ram `cat ${BOOT_DIR}/$bootvm 2>/dev/null` 
				rm -f ${TEMP_FOLDER}/reconf.tt 2>/dev/null
			fi
		;;
		3) 
			bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh l 2>/dev/null
			echo
			printf "%s" "Enter the name of the VM to reconfigure number of cpus[ENTER] "
			read name
			name=$(echo $name | awk '{print toupper($0)}') ##capitalise name
			if [ "$name" != "" ]; then
				bootvm=$(basename $(bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh s $name) 2>/dev/null)
				echo "${BOOT_DIR}/$bootvm">${TEMP_FOLDER}/reconf.tt
				config_cpu `cat ${BOOT_DIR}/$bootvm 2>/dev/null`
				rm -f ${TEMP_FOLDER}/reconf.tt 2>/dev/null
			fi
		;;
		4) 
			bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh l 2>/dev/null
			echo
			printf "%s" "Enter the name of the VM to reconfigure the sound system[ENTER] "
			read name
			name=$(echo $name | awk '{print toupper($0)}') ##capitalise name
			if [ "$name" != "" ]; then
				bootvm=$(basename $(bash ${QBOX_DIR}/bash_s/qemu-sql-vms.sh s $name) 2>/dev/null)
				echo "${BOOT_DIR}/$bootvm">${TEMP_FOLDER}/reconf.tt
				config_sound `cat ${BOOT_DIR}/$bootvm 2>/dev/null`
				rm -f ${TEMP_FOLDER}/reconf.tt 2>/dev/null
			fi
		;;
		*) break ;;
	esac
	
	echo -en "\n\n\t\t\tHit any key to continue"
		read -n 1 line
done
