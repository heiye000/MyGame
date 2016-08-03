#ifndef TCPSERVER_H_
#define TCPSERVER_H_
#include "tcpInfo.h"
#include<string>
#include<tr1/unordered_map>
#include "time_wrap.h"
struct event_base;

class CTCPServer: public iServer
{

public:
	typedef std::tr1::unordered_map<int, iEventPtr>				EventMap;		//事件列表
	typedef std::tr1::unordered_map<bufferevent*, iTCPHandlePtr>	ConnMap;		//连接列表

	CTCPServer(CFrame* p, const char* pszName, short nPort);
	virtual ~CTCPServer(void);

	virtual bool init();
	virtual void uninit();
	virtual void run();
	virtual bool AddSignal(int sigid, void* params);
	virtual void FreeSignal(int sigid);
	virtual bool SetTimer(int event_id, const timeval& time_out, void* params);
	virtual void KillTimer(int event_id);
	virtual const char* GetSvcName() const;
	virtual CFrame* GetFrame(void);
	virtual void SetDeadCheck(unsigned long sec);

	static void OnAccept(struct evconnlistener * plisten, int sock, struct sockaddr * addr, int len, void * params);
	static void OnAcceptError(struct evconnlistener *listener, void *ctx);
	static void OnSignal(int fd, short what, void *arg);
	static void OnRecv(struct bufferevent *bev, void *ctx);
	static void OnEvent(struct bufferevent *bev, short events, void *ctx);

	inline const CDeadCheck& GetDeadCheck(void) const		{ return m_deadcheck; }
	inline qTime&	GetServerTime(void)						{ return m_qtime; }
	 EventMap& GetEventMap(void) ;
	 ConnMap&  GetConnMap(void) ;

private:
	void doResetConnectEvent(iTCPHandlePtr& pHandle, iServer* pServer, struct bufferevent *bev, short events);
	void dispatch(int time_id);
	void doCheckDeadLink();

	friend class CFrame;
	std::string m_name;			//服务名称
	short m_nPort;				//服务端口 
	CFrame* m_pFrame;			//框架指针

	struct event_base* m_pBase;									//IO基础
	struct evconnlistener* m_plisterner;						//监听

	
	EventMap		m_mapEvent;									//监听事件列表<信号， 事件处理器>
	ConnMap			m_mapHandles;
	qTime			m_qtime;									//进程开启到任意时刻所经过时间（非精确）
	CDeadCheck		m_deadcheck;								//死亡链接检测
	
};

#endif