/****************************
Author:			屈天豪
Version:		v1.0
Descript:		信号事件处理类
date:			2016/7/25
tips:
*****************************/
#ifndef EVENT_H_
#define EVENT_H_
#include "iEvent.h"
#include "iServer.h"
#include "nocopyable.h"
struct event;
struct event_base;


class CEventSignal: public iEvent, public Nocopyable
{
public:
	typedef void (*OnEvent)(int sock, short, void *);
	
	CEventSignal(iServer* pServer, struct event_base* base, const OnEvent& ev);
	~CEventSignal();

	virtual void SetEvent(int event_id, const timeval& time_out, void* params);
	virtual void				KillEvent();
	virtual EventType			GetEventType();
	virtual int					GetEventId();
	virtual bool				Empty();

	inline iServer* GetServer()				{return m_pServer;}
	inline void* GetParams()				{ return m_params;}
private:
	//void Swap(CEventSignal& that);

	struct event* m_pEvent;
	int m_sigid;						//信号值
	event_base* m_pBase;				
	OnEvent m_pFun;						//信号回调
	iServer* m_pServer;					//服务器指针
	void* m_params;						//用户传递的参数

};

#endif