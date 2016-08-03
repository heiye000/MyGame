#include "tcpServer.h"
#include "assert.h"
#include<iostream>
#include "ServerFrame.h"
#include "tcpConn.h"
#include "Event.h"
//#include <netinet/in.h>
//#include <sys/socket.h>
//#include <arpa/inet.h>

#include <event2/bufferevent.h>
#include <event2/buffer.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/event.h>
#include <event2/event_struct.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include<assert.h>
#include <time.h>
#include <sys/time.h>
#include "timeEvent.h"





CTCPServer::CTCPServer(CFrame* p, const char* pszName, short nPort)
	:m_name(pszName), m_nPort(nPort), m_pFrame(p), m_deadcheck(60 * 10)
{
	m_pBase = NULL;
	m_plisterner = NULL;
	m_mapEvent.clear();
	m_mapHandles.clear();
}

CTCPServer::~CTCPServer( void )
{
	//uninit();
}

bool CTCPServer::init()
{
	LOG_DEBUG("CTCPServer::init  start .......");


	assert(m_pBase == NULL);	
	m_pBase = event_base_new();
	if (!m_pBase)
	{
		LOG_ERROR("CTCPServer::run 中 创建 event_base 失败");
		return false;
	}

	LOG_DEBUG("CTCPServer::init  start end");
	return true;
}



void CTCPServer::uninit()
{
	LOG_DEBUG("CTCPServer::uninit  start .......");

	m_mapEvent.clear();
	m_mapHandles.clear();

	if (m_plisterner)
	{
		LOG_DEBUG("释放监听套接字");
		evconnlistener_free(m_plisterner);
		m_plisterner = NULL;
	}

	if (m_pBase)
	{
		LOG_DEBUG("释放 event_base");
		event_base_free(m_pBase);
		m_pBase = NULL;
	}
	
	LOG_DEBUG("CTCPServer::uninit  end ");
	LOG_DEBUG("---------------------------------------------------------------------------------------------------------\n\n");
}

void CTCPServer::run()
{
	assert(m_pBase);
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = htonl(0);
	sin.sin_port = htons(m_nPort);

	m_plisterner =	evconnlistener_new_bind(m_pBase, CTCPServer::OnAccept, (void*)this, 
		LEV_OPT_REUSEABLE | LEV_OPT_CLOSE_ON_FREE, -1, (struct sockaddr*)&sin, sizeof(sin));
	if (!m_plisterner)
	{

		int err = EVUTIL_SOCKET_ERROR();	//错误码
		std::string strERR = evutil_socket_error_to_string(err); //错误信息
		LOG_ERROR("CTCPServer::run 中调用监听链接失败! errcode=%d, errStr=%s", err, strERR.c_str());
		return;
	}
	evconnlistener_set_error_cb(m_plisterner, CTCPServer::OnAcceptError); //设置监听错误

	//添加信号
	AddSignal(SIGINT, NULL);
	AddSignal(SIGQUIT, NULL);
	AddSignal(SIGABRT, NULL);
	AddSignal(SIGTERM, NULL);

	//死链接清理定时器
	struct timeval ti = {m_deadcheck.GetTime(), 0};
	SetTimer(80, ti, this);

	LOG_DEBUG("[CTCPServer::run]  开始事件循环...");
	event_base_dispatch(m_pBase);
	LOG_DEBUG("[CTCPServer::run] 结束事件循环.");
}


void CTCPServer::OnAccept( struct evconnlistener * plisten, int sock, struct sockaddr * addr, int 
, void * params )
{
	CTCPServer* pServer = (CTCPServer*)params;
	event_base* base = evconnlistener_get_base(plisten);
	assert(pServer && base);

	bufferevent* pbuffev = bufferevent_socket_new(base, sock, BEV_OPT_CLOSE_ON_FREE);
	assert(pbuffev);

	iTCPHandlePtr pHandle(new CTCPHandle(pServer->GetSvcName(), pServer, pbuffev) );
	pHandle->GetPeerAddress().strLoginIP = inet_ntoa( ((sockaddr_in*)addr)->sin_addr );
	pHandle->GetPeerAddress().nRemotePort = ntohs(((sockaddr_in*)addr)->sin_port); 
	
	iTCPHandlePtr& tempPtr = pServer->m_mapHandles[pbuffev];
	tempPtr = pHandle;
	bufferevent_setcb(pbuffev, CTCPServer::OnRecv, NULL, CTCPServer::OnEvent, (void*)&tempPtr);
	bufferevent_enable(pbuffev, EV_READ | EV_WRITE);

	//登录
	(pServer->GetFrame())->OnLogin(pHandle, true, pHandle->GetPeerAddress());

		
	/*LOG_DEBUG("接受一个连接，记录buff地址, ip=%s, port=%u, addr=%p", pHandle->GetPeerAddress().strLoginIP.c_str(), 
		pHandle->GetPeerAddress().nRemotePort, pbuffev);*/
	
}

void CTCPServer::OnSignal( int fd, short what, void *arg )
{
	if (what & EV_SIGNAL)	//信号
	{
		CEventSignal* pEventSig = (CEventSignal*)arg;
		CTCPServer* pServer = (CTCPServer*)pEventSig->GetServer();
		iEventPtr& iEventPtrRef = pServer->GetEventMap()[fd];

		if ((SIGINT == fd) ||
			(SIGQUIT == fd) ||
			(SIGABRT == fd) ||
			(SIGTERM == fd) )
		{
			event_base_loopexit(pServer->m_pBase, NULL); //这些信号直接退出	
		}
		else
		{
			//用户定义的信号
			(pServer->GetFrame())->OnSignal(iEventPtrRef, pEventSig->GetParams());

		}

	}
	else if (what & EV_TIMEOUT)   // 定时器
	{
		CEventTime* pEventTimer = (CEventTime*)arg;
		CTCPServer* pServer = (CTCPServer*)pEventTimer->GetServer();
		iEventPtr& iEventPtrRef = pServer->GetEventMap()[pEventTimer->GetEventId()];
		if (iEventPtrRef->GetEventId() >= 100)
		{
			//用户自定义定时器
			(pServer->GetFrame())->OnTimer(iEventPtrRef, pEventTimer->GetParams());
		}
		else
		{
			//框架定义定时器
			pServer->dispatch(pEventTimer->GetEventId());
		}
	}
	else 
	{
		//...
	}
		
}

void CTCPServer::OnAcceptError( struct evconnlistener *listener, void *ctx )
{
	
	struct event_base *base = evconnlistener_get_base(listener);
	
	int err = EVUTIL_SOCKET_ERROR();	//错误码
	std::string strERR = evutil_socket_error_to_string(err); //错误信息

	LOG_ERROR("检测到一个监听错误 %d, %s", err, strERR.c_str());

}

bool CTCPServer::AddSignal( int sigid, void* params )
{
	assert(m_pBase);
	EventMap::iterator it = m_mapEvent.find(sigid);
	if (it == m_mapEvent.end())
	{
		iEventPtr pSignal(new CEventSignal(this, m_pBase, CTCPServer::OnSignal));	//构造一个新的信号
		struct timeval tempTime = {0,0};
		pSignal->SetEvent(sigid, tempTime, params);
		m_mapEvent[sigid] = pSignal;
		return true;
	}
	else
	{
		LOG_ALERT("此信号已经存在 %d", sigid);
		return false; 
	}
	
}

void CTCPServer::FreeSignal( int sigid )
{
	if ((SIGINT == sigid) ||
		(SIGQUIT == sigid) ||
		(SIGABRT == sigid) ||
		(SIGTERM == sigid) )
	{
		LOG_ALERT("你无法移除框架默认设置的信号 %d", sigid);
		return;
	}

	EventMap::iterator it = m_mapEvent.find(sigid);
	if (it != m_mapEvent.end())
	{
		m_mapEvent.erase(it); //移除这个信号
	}
}

const char* CTCPServer::GetSvcName() const
{
	return m_name.c_str();
}

void CTCPServer::OnRecv( struct bufferevent *bev, void *ctx )
{
	//每一次有数据可读，都是把数据一次性读出来，  以后会加入缓存
	iTCPHandlePtr pConn = *(iTCPHandlePtr*)ctx;
	CTCPServer* pServer = (CTCPServer*)((CTCPHandle*)GetImplRef(pConn))->GetTCPServer();
	((CTCPHandle*)GetImplRef(pConn))->SetDeadTime(pServer->m_qtime);

	struct evbuffer *input = bufferevent_get_input(bev);
	size_t len = evbuffer_get_length(input);
	
	std::string strBuff;
	strBuff.resize(len);

	if (len)
	{
		//更新连接时间，使其处于活跃状态
		((CTCPHandle*)GetImplRef(pConn))->SetDeadTime(pServer->GetServerTime());
		//LOG_DEBUG("更新连接时间，活跃 %lu", ((CTCPHandle*)GetImplRef(pConn))->GetDeadTime().sec);

		evbuffer_remove(input, const_cast<char*>(strBuff.c_str()), len);	
		pServer->GetFrame()->OnRecvMsg(pConn, strBuff);
	}

	
}

void CTCPServer::OnEvent( struct bufferevent *bev, short events, void *ctx )
{
	int errCode = 0;
	std::string errStr;

	if (events & BEV_EVENT_ERROR)  //套接字出错
	{
		iTCPHandlePtr* pConn = (iTCPHandlePtr*)ctx;
		CTCPServer* pServer = (CTCPServer*)((CTCPHandle*)GetImplRef(*pConn))->GetTCPServer();
		pServer->doResetConnectEvent(*pConn, pServer, bev, events);

	}
	else if (BEV_EVENT_TIMEOUT & events) //超时事件
	{
		//LOG_DEBUG("BEV_EVENT_TIMEOUT");

	}
	else
	{
	//	LOG_DEBUG("BEV_EVENT_ELSE");
	}

	
	
}

CFrame* CTCPServer::GetFrame( void )
{
	return m_pFrame;
}

//iServer::EventMap& CTCPServer::GetEvents( void )
//{
//	return m_mapEvent;
//}
//
//iServer::ConnMap& CTCPServer::GetConns( void )
//{
//	return m_mapHandles;
//}

void CTCPServer::doResetConnectEvent( iTCPHandlePtr& pHandle, iServer* pServer, struct bufferevent *bev, short events)
{
	int errCode = EVUTIL_SOCKET_ERROR();
	std::string errStr = evutil_socket_error_to_string(errCode);	

	if (errCode == 104) //远端关闭连接
	{
		//对端关闭连接错误
		pServer->GetFrame()->OnLogin(pHandle, false, pHandle->GetPeerAddress());
	}
	else
	{
		//其他错误
		pServer->GetFrame()->OnError(pHandle, socket_error, errStr.c_str());
	}

	if (isUnique(pHandle)) //唯一连接,释放他
	{
		((CTCPServer*)pServer)->GetConnMap().erase(bev);
	}
	
}

 CTCPServer::EventMap& CTCPServer::GetEventMap( void ) 
{
	return m_mapEvent;
}

 CTCPServer::ConnMap& CTCPServer::GetConnMap( void ) 
{
	return m_mapHandles;
}

 bool CTCPServer::SetTimer( int event_id, const timeval& time_out, void* params )
 {
	 assert(m_pBase);
	 
	 EventMap::iterator it = m_mapEvent.find(event_id);
	 if (it != m_mapEvent.end())
	 {
		 LOG_ALERT("存在的定时器ID  %d", event_id);
		 return false; 
	 }

	 iEventPtr pTimer(new CEventTime(this, m_pBase, CTCPServer::OnSignal));
	 pTimer->SetEvent(event_id, time_out, params);
	 m_mapEvent[event_id] = pTimer;
	 return true;
 }

 void CTCPServer::KillTimer( int event_id )
 {
	 EventMap::iterator it = m_mapEvent.find(event_id);
	 if (it != m_mapEvent.end())
	 {
		 m_mapEvent.erase(it); //移除这个信号
	 }
 }

 void CTCPServer::SetDeadCheck( unsigned long sec )
 {
	 m_deadcheck.set_interval(sec);
 }

 void CTCPServer::dispatch( int time_id )
 {
	 if (time_id == 80)
	 {
		 //死链接检测
		 doCheckDeadLink();
	 }
	 else
	 {
		 //...
	 }
 }

 void CTCPServer::doCheckDeadLink()
 {
	 m_qtime = m_qtime + m_deadcheck.GetTime()*1000;

	 //现在总保有的连接数量
	int connNum = m_mapHandles.size();

	int checkNum = 0;	//需要检测多少个链接
	if ( (m_deadcheck.pos() + m_deadcheck.block()) > connNum)
	{
		checkNum = connNum - m_deadcheck.pos();
	}
	else
	{
		checkNum = m_deadcheck.block();
	}
	
	ConnMap::iterator it = m_mapHandles.begin();
	std::advance(it, m_deadcheck.pos()); // pos 之前的都已经检查过了

	//遍历一段链接， 检测是否是活跃的链接
	for (int i = 0; (it != m_mapHandles.end()) && (i < checkNum); ++i)
	{
		iTCPHandlePtr& pHandle = it->second;
		const CTCPHandle* p = (CTCPHandle*)(GetImplRef(pHandle));
		//LOG_DEBUG("连接生存时间:%lu, 服务器生存时间: %lu, 总的检测间隔:%lu", p->GetDeadTime().sec(), m_qtime.sec(), m_deadcheck.total_time_sec());

		if ( (p->GetDeadTime().sec() +  m_deadcheck.total_time_sec())  < m_qtime.sec() )
		{
			//此链接超过一定时间没有接收/发送 消息， 判定其为不活跃的链接
			m_pFrame->OnError(pHandle, socket_no_active, "the connection is not active or dead");

			if (isUnique(pHandle)) //唯一连接,释放他
			{
				it = m_mapHandles.erase(it);
				continue;
			}
		}

		++it;
	}// end for
 } 






