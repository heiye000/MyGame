#include "timeEvent.h"
#include "tcpConn.h"
#include<assert.h>

CEventTime::CEventTime(iServer* pServer, struct event_base* base, const OnEvent& ev)
	:m_pBase(base), m_pFun(ev), m_id(0), m_pEvent(NULL), m_params(NULL), m_pServer(pServer)
{
	assert(m_pBase && m_pFun && pServer);
	m_time.tv_sec = 0;
	m_time.tv_usec = 0;
}

CEventTime::~CEventTime()
{
	KillEvent();
}

void CEventTime::SetEvent(int event_id, const timeval& time_out, void* params)
{
	if(event_id < 60)
	{
		LOG_ALERT("定时器ID必须 >= 60");
		return;
	}

	if (!m_pEvent)
	{
		m_pEvent = event_new(m_pBase, -1, EV_PERSIST | EV_TIMEOUT, m_pFun, this);
		m_time = time_out; 
		m_id = event_id;
		event_add(m_pEvent, &m_time);
	}
	
	m_params = params;
}

void CEventTime::KillEvent()
{
	if (m_pEvent)
	{
		//LOG_DEBUG("释放一个定时器 id = %d", m_id);
		event_del(m_pEvent);
		event_free(m_pEvent);
		m_pEvent = NULL;
	}
}

EventType CEventTime::GetEventType()
{
	return event_timeout;
}

int CEventTime::GetEventId()
{
	return m_id;
}

bool CEventTime::Empty()
{
	return m_pEvent != NULL ? true : false;
}

