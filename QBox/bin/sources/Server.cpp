/*
Name:Nafiu Shaibu
Date:15/07/16@5:01pm
Title:Server
*/

#include <iostream>
#include <cstdlib>
#include <string.h>
#include <stdexcept>

#include <stdio.h> //fget popen pclose
#include <string>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>


#define PORTNUM 4030
//redirect bash out to c stdout
std::string exec_cmd(const char* cmd) {
    char buffer[128];
    std::string result = "";
    FILE* pipe = popen(cmd, "r");
    if (!pipe) throw std::runtime_error("popen() failed!");
    try {
        while (!feof(pipe)) {
            if (fgets(buffer, 128, pipe) != NULL)
                result += buffer;
        }
    } catch (...) {
        pclose(pipe);
        throw;
    }
    pclose(pipe);
    return result;
}

void exec_bash(int fd);

int main(int argc, char * arg[])
{
   //create a socket
   int sockfd, nSockfd;
   
   struct sockaddr_in serv_addr, cli_addr;
   
   sockfd = socket(AF_INET, SOCK_STREAM, 0);
   if(sockfd < 0){
      std::cout << "Can't open socket."<<std::endl;
      exit(1);
   }
   
   serv_addr.sin_family = AF_INET;
   serv_addr.sin_port = htons(PORTNUM);
   serv_addr.sin_addr.s_addr = INADDR_ANY;
   
   //bind to socket
   int res = bind(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr));
   if(res == -1){
      std::cout << "Can't bind socket."<<std::endl;
      exit(1);
   }
   
   //listen for connections
   listen(sockfd, 5);
   
   //Accept the connections
   int clilen = sizeof(cli_addr);
   nSockfd = accept(sockfd, (struct sockaddr *)&cli_addr, (socklen_t *)&clilen);
   
   //hand off to function
   exec_bash(nSockfd);
   
   close(nSockfd);
   close(sockfd);
   return 0;
}

void exec_bash(int fd)
{
	char buff[100];
	
	strcpy(buff, "You are successfully connected to QBox server\n");
	send(fd, buff, strlen(buff), 0);
	
	const char* buffs;
	std::string cmd = exec_cmd("ls");
	buffs = cmd.c_str();
	send(fd, buffs, strlen(buffs), 0);
}
