#ifndef __SOCKLINKER_H__
#define __SOCKLINKER_H__

#define HTTP_HEADER_MAX_LENGTH 10240

#include <stdio.h> 
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/epoll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <sys/time.h>
#include "common/mythreadpool.h"
#include "common/define.h"

enum SOCKETTYPE {
OTHER=0,
HTTPGET=1,
HTTPPOST=2
};

class SockLinker:public COMMON::Worker {
public:
	virtual int doWork();
private:
	//判断请求类型
	int CheckMSG(const char buff[], int len, const char* &output, int &outlen);
	//获取Get请求
	int HttpGetMSG();
	//获取Post请求
	int HttpPostMSG();
	//URL解码
	int URLEncode(const char *input, int len, char *output, int &outlen);
	int URLDecode(const char *url, const int len, char *output, const int outlen);
	char unhex(unsigned char c);

	int trecv(int fd, void *buff, size_t n, timeval *timeout);
	int tread(int fd, void *buff, size_t n, timeval *timeout);
	int generateHttpHeader(std::string& res, int len);
public:
	int sockfd;
};

#endif
