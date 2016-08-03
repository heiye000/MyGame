/****************************
Author:			屈天豪
Version:		v1.0
Descript:		定时器事件实现类
date:			2016/7/25
tips:
*****************************/
#ifndef TIMEEVENT_H_
#define TIMEEVENT_H_
#include "iEvent.h"
#include"iServer.h"
#include "nocopyable.h"
#include "event2/event.h"


class CEventTime : public iEvent, public Nocopyable
{
public:
	typedef void (*OnEvent)(int sock, short, void *);

	CEventTime(iServer* pServer, struct event_base* base, const OnEvent& ev);
	~CEventTime();

	virtual void				SetEvent(int event_id, const timeval& time_out, void* params);
	virtual void				KillEvent();
	virtual EventType			GetEventType();
	virtual int					GetEventId();
	virtual bool				Empty();
	inline void* GetParams()				{ return m_params;}
	inline iServer* GetServer()				{return m_pServer;}
private:
	struct event* m_pEvent;
	int m_id;				//唯一id值
	event_base* m_pBase;				
	OnEvent m_pFun;					//信号回调
	void* m_params;					//用户传递的参数
	timeval m_time;					//定时器间隔
	iServer* m_pServer;			
};

#endif