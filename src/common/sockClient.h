#ifndef __SOCKETCLIENT__
#define __SOCKETCLIENT__

#include <string>
#include <stdio.h>  
#include <string.h>  
#include <sys/socket.h>  
#include <netinet/in.h>  
#include <stdlib.h>  
#include <syslog.h>  
#include <errno.h>  
#include <arpa/inet.h>
#include "mythreadpool.h"

namespace MYSOCK {

class SocketClient:public COMMON::Worker {
public:
	virtual int doWork() {}
	SocketClient(const std::string &addr, const long &timeout = -1, const bool &debug = false);
	//初始化 创建fd 创建链接 不在构造函数中init 因为如此可以返回异常状态
	bool init();
	//发送数据
	bool send(const std::string &data);
	//接受数据
	bool recv(std::string &data);
	//析构函数中自动关闭fd
	~SocketClient();
	//关闭 fd
	bool close();
private:
	//接受数据
	bool recv();
private:
	enum {MAXLENGTH = 1024*10};

	int m_scok_fd;
	std::string m_ip;
	int m_port;
	long m_timeout;
	struct sockaddr_in m_real_addr;
	char *m_buffer;
	bool m_usring;
	bool m_debug;
};

}
#endif
