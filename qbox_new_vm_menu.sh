#!/bin/bash

: ${LIB_DIR:=$HOME/my_script/QB}

. ${LIB_DIR}/include

if NOT_DEFINE ${CURSES_DIALOG_H}; then
	. ${LIB_DIR}/include '<curses_dialog.h>'
fi 

while : ; do 
	
	exec 3>&1
		value=$(${DIALOG} \
				--no-shadow --clear --extra-button --extra-label "Back" --colors --title "\Zb\Z0Create New Virtual Machine\Zn\ZB" \
				--menu "\Zb\Z0Create New VM\Zn\ZB\nThis menu will help you configure the VM." ${HEIGHT} ${WIDTH} 3 1 "Basic configurations" \
				2 "Network configurations" 3 "Select Boot device" 2>&1 1>&3)
	
		let "test_return=$?"
	exec 3>&-

	case ${test_return} in 
		${DIALOG_OK}) 
			if [[ $value -eq 1 ]]; then
				. ${LIB_DIR}/qbox_create_vm.sh 
			elif [[ $value -eq 2 ]]; then
				. ${LIB_DIR}/qbox_network_config.sh 
			elif [[ $value -eq 3 ]]; then
				. ${LIB_DIR}/qbox_boot_device.sh 
			fi 
		;;
		${DIALOG_BACK}) break ;;
	esac
done
