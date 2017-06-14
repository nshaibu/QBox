#!/usr/bin/python 

import netifaces as nk


inter_faces = nk.interfaces()

def main():
	for i in inter_faces:
		if 'eth' in i:
			try:
				nk.ifaddresses(i)[2][0]['addr']
				print(nk.ifaddresses(i)[2][0]['addr'])
			except:
				pass
		elif 'wlan' in i:
			try:
				nk.ifaddresses(i)[2][0]['addr']
				print(nk.ifaddresses(i)[2][0]['addr'])
			except:
				pass

if __name__ == '__main__':
	main()
