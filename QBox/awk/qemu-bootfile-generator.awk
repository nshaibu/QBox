#!/bin/gawk -f

###################################################
# 		Purpose: Help to Generate Boot files	  #
###################################################


BEGIN{
	var[1]="archtype"
	var[2]="vm_name"
	var[3]="cpu"
	var[4]="smp"
	var[5]="ram"
	var[6]="vga"
	var[7]="display"
	var[8]="network0"
	var[9]="vlan0"
	var[10]="mac0"
	var[11]="model0"
	var[12]="user0"
	var[13]="vlan_user0"
	var[14]="redirect0"
	var[15]="tap0"
	var[16]="vlan_tap0"
	var[17]="fd_tap0"
	var[18]="ifname0"
	var[19]="script0"
	var[20]="socket0"
	var[21]="vlan_sock0"
	var[22]="fd_sock0"
	var[23]="listen0"
	var[24]="connect0"
	var[25]="mcast0"
	var[26]="network1"
	var[27]="vlan1"
	var[28]="mac1"
	var[29]="model1"
	var[30]="user1"
	var[31]="vlan_user1"
	var[32]="redirect1"
	var[33]="tap1"
	var[34]="vlan_tap1"
	var[35]="fd_tap1"
	var[36]="ifname1"
	var[37]="script1"
	var[38]="socket1"
	var[39]="vlan_socket1"
	var[40]="fd_socket1"
	var[41]="listen1"
	var[42]="connect1"
	var[43]="mcast1"	
	var[44]="network2"
	var[45]="vlan2"
	var[46]="mac2"
	var[47]="model2"
	var[48]="user2"
	var[49]="vlan_user2"
	var[50]="redirect2"
	var[51]="hostname2"
	var[52]="tap2"
	var[53]="vlan_tap2"
	var[54]="fd_tap2"
	var[55]="ifname2"
	var[56]="script2"
	var[57]="socket2"
	var[58]="vlan_socket2"
	var[59]="fd_socket2"
	var[60]="listen2"
	var[61]="connect2"
	var[62]="mcast2"	
	var[63]="network3"
	var[64]="vlan3"
	var[65]="mac3"
	var[66]="model3"
	var[67]="user3"
	var[68]="vlan_user3"
	var[69]="redirect3"
	var[70]="tap3"
	var[71]="vlan_tap3"
	var[72]="fd_tap3"
	var[73]="ifname3"
	var[74]="script3"
	var[75]="socket3"
	var[76]="vlan_socket3"
	var[77]="fd_socket3"
	var[78]="listen3"
	var[79]="connect3"
	var[80]="mcast3"
	var[81]="smb"
	var[82]="audio"
	var[83]="usb"
	var[84]="hdk"
	var[85]="kvm"
	var[86]="kernel"
	var[87]="initrd"
	var[88]="keyboard"
	var[89]="fullscreen"
	var[90]="priority"
	var[91]="snapshot"
	var[92]="kernelcmd"
	var[93]="monitordev"
	var[94]="localtime"
}


#ACTION

{
	for(i=1; i<=NF; i++){ 
		printf "%s|%s\n", var[i], $i
	}
}
