/****************************
Author:			屈天豪
Version:		v1.0
Descript:		TCP连接处理类
date:			2016/7/25
tips:
*****************************/
#ifndef TCPCONN_H_
#define TCPCONN_H_
#include "tcpInfo.h"
#include "nocopyable.h"
#include "time_wrap.h"
struct bufferevent;

class CTCPHandle: public iConnHandle, private Nocopyable
{
public:
	CTCPHandle(const char* pszSvcName, iServer* pServer, struct bufferevent* pbuffev);
	virtual ~CTCPHandle();

	virtual const char* GetSvcName(void) const;
	virtual bool SendMsg(const char* pszMsg, int len);
	virtual SLoginInfo& GetPeerAddress(void);

	const int GetSocket() const;
	iServer* GetTCPServer(void);
	inline const qTime& GetDeadTime(void) const				{ return m_currenttime; }
	inline void SetDeadTime(const qTime& ti)				{ m_currenttime = ti; }
private:
	struct bufferevent* m_pbuffev;				
	std::string m_strSvcName;
	iServer* m_pServer;
	SLoginInfo m_loginInfo;						//登录信息
	qTime m_currenttime;						//死亡检测时间， 每次进行收发消息，此值会跟新，当长时间没有更新此值，则判定此连接为不活跃的连接
};
#endif