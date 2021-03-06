#!/bin/bash

: ${LIB_DIR:=/usr/local/bin/QBox/include_dir}

. ${LIB_DIR}/define_macros

if NOT_DEFINE ${CURSES_DIALOG_H} || NOT_DEFINE ${BASIC_UTILS_H} || NOT_DEFINE ${BOOT_SYSTEM_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
	. ${LIB_DIR}/include '<basic_utils.h>'
	. ${LIB_DIR}/include '<boot_system.h>'
fi

if NOT_DEFINE ${ARCHITECTURE_H}; then
	. ${LIB_DIR}/include '<architecture.h>'
fi


function until_is_iso_file() {
	let value=$1
	until check_is_file $value && check_is_iso_file $value ; do
		exec 3>&1
		value=`${DIALOG} \
			--no-shadow --colors --clear --title "\Zb\Z0Select a file\Zn\ZB" \
			--fselect $HOME/ 10 50 2>&1 1>&3`
		exec 3>&-
		#Sat 18 Feb 2017 05:55:42 PM GMT 
		[ $_return -eq ${DIALOG_CANCEL} ] && break 2
	done
	
	eval $2="${value}"
	detect_architecture $value
	architecture_type_choice $?
}


while true; do
	exec 3>&1
	
	value=`${DIALOG} \
		--no-tags --no-shadow --clear --ok-label "Next" --cancel-label "Back" --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
		--radiolist "\Zb\Z0Boot Disk\Zn\ZB \nChoose a boot device to use. The boot device could be either a cdrom or floppy disk. You can use the host floppy device(/dev/fb0) or host cdrom device(/dev/cdrom).\n\nPress \Zb\Z0SPACE-KEY\Zn\ZB to make a choice." ${HEIGHT} ${WIDTH} 2 1 "Floppy Disk" off 2 "CD ROM" on 2>&1 1>&3`
	
	let "test_return=$?"
	exec 3>&-
	
	case ${test_return} in 
		${DIALOG_OK}) 
			[[ $value -eq 1 ]] && {
				exec 3>&1
				
				value=`${DIALOG} \
					--no-shadow --clear --ok-label "Next" --extra-button --extra-label "Back" --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
					--menu "\Zb\Z0Floppy Disk Type\Zn\ZB\nChoose a host floppy device or Disk image file" ${HEIGHT} ${WIDTH} 2 \
					1 "Disk Image File[ISO File]" 2 "Host Floppy Device" 2>&1 1>&3`
				
				let "test_return=$?"
				exec 3>&-
				
				case ${test_return} in 
					${DIALOG_OK}) 
						if [[ $value -eq 1 ]]; then
							until_is_iso_file $value iso_file
							
							VM_CDROM="-cdrom ${iso_file}"
						else
							VM_CDROM="-cdrom /dev/fb0"
						fi 
						break
					;;
					${DIALOG_CANCEL}) break ;;
				esac
			} || {
				exec 3>&1
				
				value=`${DIALOG} \
					--no-shadow --clear --ok-label "Next" --extra-button --extra-label "Back" --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
					--menu "\Zb\Z0Floppy Disk Type\Zn\ZB\nChoose a host cdrom device or Disk image file" ${HEIGHT} ${WIDTH} 2 \
					1 "Disk Image File[ISO File]" 2 "Host CDROM Device" 2>&1 1>&3`	
				
				let "test_return=$?"
				exec 3>&-
				
				case ${test_return} in 
					${DIALOG_OK}) 
						if [[ $value -eq 1 ]]; then
							until_is_iso_file $value iso_file
							VM_CDROM="-cdrom ${iso_file}"
						else
							VM_CDROM="-cdrom /dev/cdrom"
						fi 	
						
						if ! boot_system ; then
							break
						fi 
					;;
					${DIALOG_BACK}) ;;
					${DIALOG_CANCEL}) break ;;
				esac			
			}
		;;
		${DIALOG_CANCEL}) break ;;
	esac
	
done
