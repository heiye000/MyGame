#ifndef __SOCKET_SERVER_H__
#define __SOCKET_SERVER_H__

#include <stdio.h> 
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/epoll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include "mythreadpool.h"
#include "sockLinker.h"

class SocketServer:public COMMON::MyThreadpool {
public:
	SocketServer(const int thread_num, const int port);
	int open();
	//int UseConnectFd(int sockfd);
private:
	int InitEpollFd();
	int CreateTcpListenSocket();
	int setnonblocking(int sock);
public:
	int m_port;	//端口
	int m_listenfd;	//本机监听的socket

	int BUF_EV_LEN;
	int MAX_EPOLL_FD;
	int BACKLOG;
};

#endif