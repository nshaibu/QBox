#!/bin/gawk -f

#########################################################
# 		Purpose: To detect Architecture of ISO File		#
#########################################################

BEGIN{ 
	ARH_TYPE[0]="x86_64" 
	ARH_TYPE[1]="x86" 
	ARH_TYPE[2]="amd64" 
	ARH_TYPE[3]="i386" 
	ARH_TYPE[4]="arm" 
	ARH_TYPE[5]="ppc" 
	ARH_TYPE[6]="ppc64" 
	ARH_TYPE[7]="sparc" 
	ARH_TYPE[8]="sparc64" 
	ARH_TYPE[9]="mips" 
	ARH_TYPE[10]="mipsel" 
	ARH_TYPE[11]="i686" 
	ARH_TYPE[12]="armeb"
}


#ACTION
{
	for (i=0; i<=10; ++i)
	{
		if(match($0, ARH_TYPE[i])){
			print ARH_TYPE[i]
			break
		}
	}
}
