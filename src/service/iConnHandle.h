/****************************
Author:			屈天豪
Version:		v1.0
Descript:		连接接口类
date:			2016/7/25
tips:
*****************************/
#ifndef ICONNHANDLE_H_
#define ICONNHANDLE_H_
#include <string>
struct SLoginInfo;


class iConnHandle
{
public:
	iConnHandle(){}
	virtual ~iConnHandle(){}

	/*
		获取该连接属于哪个服务的服务名（框架开启时需要给定一个服务名称参数）	
	*/
	virtual const char* GetSvcName(void) const			= 0;


	/*
		发送消息， 立即发送
	*/
	virtual bool SendMsg(const char* pszMsg, int len)	= 0;

	
	/*
		获取对端的地址信息和端口信息
	*/
	virtual SLoginInfo& GetPeerAddress(void)			= 0;
};

#endif