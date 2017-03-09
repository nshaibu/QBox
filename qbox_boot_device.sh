#!/bin/bash

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include

if NOT_DEFINE ${CURSES_DIALOG_H} ; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
fi

declare -i HEIGHT=18
declare -i WIDTH=50

while true; do
	exec 3>&1
	
	value=`${DIALOG} \
		--no-tags --no-shadow --clear --ok-label "Next" --colors --title "\Zb\Z0Create Virtual Machine\Zn\ZB" \
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
							exec 3>&1
							value=`${DIALOG} \
								--no-shadow --colors --clear --title "\Zb\Z0Select a file\Zn\ZB" \
								--fselect $HOME/ 10 50 2>&1 1>&3`
							exec 3>&-
							echo $value 
							break		
						else
							VM_CDROM="-cdrom /dev/fb0"
						fi 
					;;
					${DIALOG_BACK}) ;;
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
							
							let "chk_is_dir=${SUCCESS}"
								
							while [ ${chk_is_dir} -ne ${FAILURE} ]; do 
								exec 3>&1
								value=`${DIALOG} \
									--no-shadow --colors --clear --title "\Zb\Z0Select a file\Zn\ZB" \
									--fselect $HOME/ 10 50 2>&1 1>&3`
								exec 3>&-
								#Sat 18 Feb 2017 05:55:42 PM GMT 
								[[ ! -f $value ]] && {
									chk_is_dir=${FAILURE}
								} || {
									
									${DIALOG} \
										--and-widget --colors --msgbox "\nNot a file $value" $((HEIGHT-7)) $((WIDTH-7))
										
									chk_is_dir=${FAILURE}
								}
							#break
							
							done
						else
							VM_CDROM="-cdrom /dev/cdrom"
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
