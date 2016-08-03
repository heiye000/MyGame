#include "Event.h"
#include "tcpInfo.h"
#include <signal.h>
#include <fcntl.h>
#include <event.h>
#include<assert.h>

CEventSignal::CEventSignal(iServer* pServer, struct event_base* base, const OnEvent& ev)
	:m_pBase(base), m_pFun(ev), m_sigid(0), m_pServer(pServer), m_pEvent(NULL), m_params(0)
{
	assert(m_pBase && ev && pServer);
	
}

//CEventSignal::CEventSignal( const CEventSignal& that )
//{
//	m_sigid = that.m_sigid;
//	m_pFun = that.m_pFun;
//	m_pBase = that.m_pBase;
//	m_params = that.m_params;
//	m_pEvent = evsignal_new(m_pBase, m_sigid, m_pFun, m_params);
//	assert(m_pEvent != NULL);
//}
//
//CEventSignal& CEventSignal::operator=( const CEventSignal& that )
//{
//	CEventSignal temp(that);
//	temp.Swap(*this);
//	return *this;
//}

CEventSignal::~CEventSignal()
{
	KillEvent();
}

void CEventSignal::SetEvent(int event_id, const timeval& time_out, void* params)
{
	m_params = params;

	if (m_pEvent == NULL)
	{
		m_sigid = event_id;
		m_pEvent = evsignal_new(m_pBase, m_sigid, m_pFun, this);
		if(!m_pEvent)
		{
			//LOG_ERROR("创建一个信号失败 %lu", time_out);
			return;
		}
	}

	assert(m_pEvent);
	event_add(m_pEvent, NULL);
}

void CEventSignal::KillEvent()
{
	if (m_pEvent)
	{
		//LOG_DEBUG("释放信号: %d, addr=%p", GetEventId(), m_pEvent);
		event_del(m_pEvent);
		event_free(m_pEvent);
		m_pEvent = NULL;
	}
	
}

EventType CEventSignal::GetEventType()
{
	return event_signal;
}

int CEventSignal::GetEventId()
{
	return m_sigid;
}

bool CEventSignal::Empty()
{
	return m_pEvent != NULL ? true : false;
}

//void CEventSignal::Swap(CEventSignal& that )
//{
//	m_sigid = that.m_sigid;
//	m_pFun = that.m_pFun;
//	m_pBase = that.m_pBase;
//	m_params = that.m_params;
//
//	//交换
//	struct event* pTemp = m_pEvent;
//	m_pEvent = that.m_pEvent;
//	that.m_pEvent = pTemp;
//
//}




