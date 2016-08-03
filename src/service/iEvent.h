/****************************
Author:			屈天豪
Version:		v1.0
Descript:		事件接口类
date:			2016/7/25
tips:
*****************************/

#ifndef IEVENT_H_
#define IEVENT_H_
#include<time.h>
#include <sys/time.h>
/*
	事件类型
*/
enum EventType
{
	event_signal = 0,		//信号事件
	event_timeout,			//定时器事件
};

class iEvent
{
public:
	iEvent() {}
	virtual ~iEvent() {}

	/*
		设置一个事件， 这个事件可以是一个定时器或者一个信号
		参数 1：
			如果是一个信号， 参数是一个信号码
			如果是个定时器， 参数是这个定时器的唯一id

		参数2： 
			如果是一个信号， 参数值无效
			如果是个定时器， 则是时间间隔
	*/
	virtual void SetEvent(int event_id, const timeval& time_out, void* params) =0;

	/*
		释放这个事件
	*/
	virtual void KillEvent()							= 0;


	/*
		获取一个事件的类型
	*/
	virtual EventType GetEventType()					= 0;


	/*
		如果事件类型是一个信号， 则此调用获取该信号的 信号值
		如果事件类型是一个定时器，则此调用获取该定时器的唯一标识
	*/
	virtual int	 GetEventId()							= 0;

	/*
		该信号或者定时器是否已经被设置， true 表示设置了， false 表示没有设置，表示一种存活状态
	*/
	virtual bool		Empty()							= 0;
};

#endif