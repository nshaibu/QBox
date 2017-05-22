#!/bin/gawk -f


{
	if ( $2 !~ var ) {
		print $0
	}
}
