#!/bin/bash
let _test=0
let _dtest=0

if [ -d /usr/local/bin/QBox ]; then
	
	echo -e "Removing QBox...\n"
	pushd /usr/local/bin 1>/dev/null 2>&1
	rm -r QBox && _test=1
	popd 1>/dev/null 2>&1
	
elif [ -f /usr/share/applications/QBox.desktop ]; then
	
	pushd /usr/share/applications >/dev/null 2>&1
	rm -f QBox.desktop && _dtest=1
	popd >/dev/null 2>&1
	
fi

if [ $_test -eq 0 -a $_dtest -eq 0 ]; then
	echo -e "QBox not removed."
else
	printf "%s\n" "QBox removed"
	update-desktop-database "/usr/share/applications/"
fi

exit 0
