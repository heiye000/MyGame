#include "sockClient.h"
#include "mycommonfuc.h"
#include <iostream>
#include <string>
#include <stdlib.h>
#include <unistd.h>

using namespace std;

/*
connect(fd, (struct sockaddr *)&m_real_addr, sizeof(m_real_addr))
返回-1为异常
连接远程服务器 

bzero(void *s, int n);   制零 (地址,字节数)
inet_pton(int af, cosnt char *src, void *dst);  将“点分十进制” －> “二进制整数”


send 返回实际发送数据的数量

int getpeername(int sockfd, struct sockaddr *addr, int *addrlen);  告诉你在连接的流式套接字上谁在另外一边
*/
namespace MYSOCK {

SocketClient::SocketClient(const std::string &addr, const long &timeout, const bool &debug) {
	int pos = -1;
	if((pos = addr.find(":")) == string::npos) {
		cerr << "addr error: " << addr << endl;
		exit(1);
	}

	m_ip = addr.substr(0, pos);
	m_port = COMMON::convert<string, int>(addr.substr(pos + 1));
	m_timeout = timeout;

	//bzero(&m_real_addr, sizeof(m_real_addr));
	memset(&m_real_addr, 0, sizeof(m_real_addr));
	
	m_real_addr.sin_family = AF_INET;
	m_real_addr.sin_port = htons(m_port);
	inet_pton(AF_INET, m_ip.c_str(), &m_real_addr.sin_addr);
	m_buffer = new char[MAXLENGTH];
	//标记没有被使用
	m_usring = false;
	m_debug = debug;
}

SocketClient::~SocketClient() {
	this->close();
	delete[] m_buffer;
}

bool SocketClient::init() {
	if((m_scok_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		cerr << "socket create error!" << endl;
		return false;
	}
	m_usring = true;
	if(connect(m_scok_fd, (struct sockaddr *)&m_real_addr, sizeof(m_real_addr)) == -1) {
		cerr << "connect error!" << endl;
		this->close();
		return false;
	}
	return true;
}


bool SocketClient::send(const std::string &data) {
	int flag = 0;
	while(flag < data.length()+1) {
		flag = ::send(m_scok_fd, data.c_str() + flag, data.length()+1, 0);
		if(flag == -1) {
			cout << "send error" << endl;
			return false;
		}
	}
	if(m_debug) {
		cout << "send ok" << endl;
	}
	return true;
}

/*
int SocketClient::trecv(int fd, void *buff, size_t n, timeval *timeout) {
	bzero(m_buffer, MAXLENGTH);
	int left = n;
	fd_set wset;
	while(MAXLENGTH- > 0) {
		FD_ZERO(&wset);
		FD_SET(fd, &wset);
		int ret = select(fd+1, NULL, &wset, NULL, timeout);
		if(ret <= 0) {
			return -1;
		}
		ret = write(fd, buff, left);
		if(ret == 0) {
			return left - ret;
		}
		buff = ((char *)buff)+ret;
		left -= ret;
	}
	return n;
}*/

bool SocketClient::recv() {
	std::cerr << "recv ..." << std::endl;
	bzero(m_buffer, MAXLENGTH);
	int retlen = ::recv(m_scok_fd, m_buffer, MAXLENGTH, 0);
	std::cerr << "recv end  " << m_buffer << std::endl;
	m_buffer[retlen] = 0;
	if(retlen < 0) {
		cerr << "recv error!  retlen = " << retlen << endl;
		return false;
	}
	if(m_debug) {
		cout << "read:" << *m_buffer << endl;
	}
	return true;
}

bool SocketClient::recv(std::string &data) {
	std::cerr << "recv start!" << std::endl;
	if(this->recv()) {
		data = *m_buffer;
		return true;
	}
	return false;
}

bool SocketClient::close() {
	if(m_usring) {
		::close(m_scok_fd);
		m_usring = false;
	}
	return true;
}



//非阻塞read
/*int SocketClient::tread(int fd, void *buff, size_t n, timeval *timeout) {
	fd_set rset;
	FD_ZERO(&rset);
	FD_SET(fd, &rset);
	int ret = select(fd+1, &rset, NULL, NULL, timeout);
	if(ret <= 0) {
		return -1;
	}
	ret = read(fd, buff, n);
	if(ret <= 0) {
		return ret;
	}
	((char *)buff)[ret] = '\0';
	return ret;
}*/

}
