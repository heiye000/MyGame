#include "tcpConn.h"
#include <event2/bufferevent.h>
#include <event2/buffer.h>
#include <event2/util.h>
#include <event2/event.h>
#include <event2/event_struct.h>
#include <event2/listener.h>
#include "tcpServer.h"
#include <sys/socket.h>
#include "timeEvent.h"

CTCPHandle::CTCPHandle(const char* pszSvcName, iServer* pServer, struct bufferevent* pbuffev)
	:m_pbuffev(pbuffev), m_strSvcName(pszSvcName), m_pServer(pServer), m_currenttime( ((CTCPServer*)pServer)->GetServerTime() )
{
}

CTCPHandle::~CTCPHandle()
{
	if (m_pbuffev)
	{
		//LOG_DEBUG("释放一个连接 ip=%s, port = %u, m_pbuff = %p", m_loginInfo.strLoginIP.c_str(), m_loginInfo.nRemotePort, m_pbuffev);
		bufferevent_free(m_pbuffev);
		m_pbuffev = NULL;
	}
}

const char* CTCPHandle::GetSvcName( void ) const
{
	return m_strSvcName.c_str();
}



bool CTCPHandle::SendMsg( const char* pszMsg, int len )
{
	//写入缓存区
	return bufferevent_write(m_pbuffev, pszMsg, len) == 0 ? true : false;
}

 SLoginInfo& CTCPHandle::GetPeerAddress( void ) 
{
	return m_loginInfo;
}

 iServer* CTCPHandle::GetTCPServer( void )
 {
	return m_pServer;
 }

 const int CTCPHandle::GetSocket() const
 {
	 return bufferevent_getfd(m_pbuffev);
 }



