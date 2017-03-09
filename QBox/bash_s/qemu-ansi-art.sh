#!bin/bash

###################################################
# 			Purpose: ASCII Drawings				  #
###################################################

QDATA[0]="                 _/_/_/      _/_/_/                          "
QDATA[1]="               _/     _/   _/     _/     _/_/     _/   _/    "
QDATA[2]="              _/      _/  _/ _/_/_/    _/    _/   _/  _/     "
QDATA[3]="             _/      _/  _/       _/  _/     _/    _/  _/    "
QDATA[4]="              _/_/_/\_\ _/_/_/_/_/     _/_/_/     _/   _/    "
QDATA[5]="                      loading QBox...                        "
QDATA[6]="                 Copyleft (C) 2016 Nafiu Shaibu.             "
QDATA[7]="                                                             "
# virtual coordinate system is X*Y ${#QDATA} * 5

REAL_OFFSET_X=0
REAL_OFFSET_Y=0

##Draws the characters in the arrays declared above
draw_characters() {
	V_COORD_X=$1
	V_COORD_Y=$2

	##changing the position of the cursor to x y
	tput cup $((REAL_OFFSET_Y + V_COORD_Y)) $((REAL_OFFSET_X + V_COORD_X))

	printf %c ${QDATA[V_COORD_Y]:V_COORD_X:1}
}


trap 'exit 1' INT TERM
trap 'tput sgr0; tput cvvis; clear' EXIT

tput civis
clear

let x=0

while true 
do
	for ((c=1; c <= 7; c++)) 
	do
  	    tput setaf $c
  		for ((x=0; x<${#QDATA[0]}; x++))
  		do
    			for ((y=0; y<=7; y++))
    			do
    				draw_characters $x $y
    			done
		done
	done
   break
done

tput sgr0 ## reset everything

exit 0
