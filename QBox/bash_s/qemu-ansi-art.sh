#!bin/bash

###################################################
# 			Purpose: ASCII Drawings				  #
###################################################

: ${LIB_DIR:=$HOME/my_script/QB/QBox/include_dir}
. ${LIB_DIR}/include 
. ${LIB_DIR}/import '<init.h>'

QDATA[0]="                 _/_/_/      _/_/_/                          "
QDATA[1]="               _/     _/   _/     _/     _/_/     _/   _/    "
QDATA[2]="              _/      _/  _/ _/_/_/    _/    _/   _/  _/     "
QDATA[3]="             _/      _/  _/       _/  _/     _/    _/  _/    "
QDATA[4]="              _/_/_/\_\ _/_/_/_/_/     _/_/_/     _/   _/    "
QDATA[5]="                      loading QBox...                        "
QDATA[6]="                 Copyleft (C) 2017 Nafiu Shaibu.             "
QDATA[7]="                                                             "
# virtual coordinate system is X*Y ${#QDATA} * 5

let x_tty_cord=$(_tty_tigetnum "columns") 
let y_tty_cord=$(_tty_tigetnum "rows")

let x_cord_art=${#QDATA[0]}

x_cord=$(( (x_tty_cord-x_cord_art) / 2 ))
y_cord=$(( (y_tty_cord-8) / 2 ))

REAL_OFFSET_X=${x_cord}
REAL_OFFSET_Y=${y_cord}

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

while true 
do
	for ((c=1; c <= 7; c++)) 
	do
  	    tput setaf $c
  		for ((x=0; x<${#QDATA[0]}; x++))
  		do
    			for ((y=0; y<=7; y++)); do 
    				draw_characters $x $y
    			done
		done
	done
   break
done

tput sgr0 ## reset everything
