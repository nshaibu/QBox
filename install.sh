#!/bin/bash


[ ! -d /usr/local/bin/QBox ] && {
	dialog --title "[1]Installation" --pause "Installing QBox..." 15 50 4
	#echo "[1]installing QBox..." && sleep 2
	
	curdir=`pwd` && cd /
	
	mkdir /usr/local/bin/QBox
	cd $curdir && cd / 
	
	cp -ar $curdir/QBox/. /usr/local/bin/QBox 2>/dev/null
	
	#check=`cat $HOME/.profile | grep QBox`
	#if [ "$check" = "" ]; then
	#	echo -e "\n##QBox path \n[ -d /opt/QBox ] && PATH=/opt/QBox:\${PATH}">>${HOME}/.profile
	#fi
	cp -a $curdir/QBox/QBox.desktop /usr/share/applications 2>/dev/null
	
	
	cd $curdir
	 
	if [ ! -d /usr/local/bin/QBox ]; then
		cd / && cd /usr/local/bin
		rm -rf QBox	
		rm -f /usr/share/applications/QBox.desktop
		dialog  --title "[3]Usage" --msgbox "QBox not installed!!! usage:sudo ./install.sh" 20 40 
		#printf "%s\n" "[2]QBox not installed!!! usage:sudo ./install.sh"
		cd $curdir
		exit 1
	else
		dialog --title "[3]Finishing" --pause "finishing..." 15 50 4
		cd / && cd /usr/local/bin
		chmod -R -f 777 QBox/
		#echo -e "\n\n [2]QBox installed successfully" && sleep 2
		cd $curdir
		update-desktop-database "/usr/share/applications/" 
	fi
	 
} || {
	dialog --title "[1]Installed" --msgbox "QBox already installed!!!" 15 50
	#echo -e "\t\t[3]QBox already installed!!!" && sleep 2

}

clear

exit 0
