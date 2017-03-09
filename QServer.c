#include <stdio.h> 
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>


extern int errno;
#define PORTNUM 4030

char* prom = NULL;


void reconfigure(){
	
}

void vm_boot(){

}

int prompt(int mode, char* pcmd, int sock){
	int _mode;
	
	if ( mode == 0 ){
		_mode=0;
		sprintf(prom, "%s(boot)>", pcmd );
		send(sock, prom, strlen(prom), 0);
	
	}else{
		_mode=1;
		sprintf(prom, "%s(reconfig)>", pcmd);
		send(sock, prom, strlen(prom), 0);
	
	}
	
	return _mode;
}

void handler(int sock ){
	
	char addrbuf[128];
	struct sockaddr_in hostaddr;
	int addrsize=sizeof(struct sockaddr);
	
	if ((getsockname(sock, (struct sockaddr *)&hostaddr, &addrsize)) < 0){
		fprintf(stderr, "[Error]: %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}else{
		sprintf(addrbuf, "[%s:%d]~", inet_ntoa(hostaddr.sin_addr), ntohs(hostaddr.sin_port));
	}
	
	
	
	while (1){
	//	prompt(0, addrbuf, sock);
		send(sock, addrbuf, strlen(addrbuf), 0);
	}
}

int main(int argc, char * arg[])
{
	//create a socket
	int sockfd, nsockfd, resfd;
	
	struct sockaddr_in serv_address, cli_address;
	
	if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
	{
		
		fprintf(stderr, "[Error]: %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}
	
	serv_address.sin_family = AF_INET;
	serv_address.sin_port = htons(PORTNUM);
	serv_address.sin_addr.s_addr = INADDR_ANY;
	
	//bind to socket
	if ( (resfd = bind(sockfd, (struct sockaddr *)&serv_address, sizeof(serv_address)) ) == -1)
	{
		
		fprintf(stderr, "[Error]: %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}
	
	//listen for connections
	if ((listen(sockfd, SOMAXCONN)) < 0)
	{
		fprintf(stderr, "[Error]: %s\n", strerror(errno));
		exit(EXIT_FAILURE);		
	}
	
	//Accept the connections
	int clilen = sizeof(cli_address);
	nsockfd = accept(sockfd, (struct sockaddr *)&cli_address, (socklen_t *)&clilen);
	
	//hand off to function
	handler(nsockfd);
	
	close(nsockfd);
	close(sockfd);
	
	return 0;
}

