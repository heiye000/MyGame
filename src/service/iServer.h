/****************************
Author:			屈天豪
Version:		v1.0
Descript:		服务接口
date:			2016/7/25
tips:
*****************************/

#ifndef ISERVER_H_
#define ISERVER_H_
#include<map>

struct bufferevent;
class CFrame;
struct timeval;

class iServer
{
public:
	iServer(){}
	virtual ~iServer(){}


	/*
		设置捕获一个信号， 当有此信号发生时， 会通告框架程序
		参数:
			sigid			信号码
			params			参数传递，你传入的参数在信号发生时会通过 params 传递给你
	*/
	virtual bool AddSignal(int sigid, void* params)			= 0;

	/*
		释放一个信号
	*/
	virtual	void FreeSignal(int sigid)			= 0;


	/*
		设置定时器
		参数：
			event_id			信号唯一id  
			time_out			定时器间隔
			params				...

		备注：
			定时器ID  必须大于 100
	*/
	virtual bool SetTimer(int event_id, const timeval& time_out, void* params) = 0;

	/*
		释放定时器
	*/

	virtual void KillTimer(int event_id)				= 0;


	/*
		获取服务名称
	*/
	virtual const char* GetSvcName() const		= 0;


	/*
		获取框架接口
	*/
	virtual CFrame* GetFrame(void)				= 0;


	/*
		检测死亡连接的时间间隔
		请在初始化的时候设置
		
		参数：
			sec			间隔的秒数
		备注：
			默认的时间间隔是10 分钟
	*/
	virtual void SetDeadCheck(unsigned long sec)		= 0;


	virtual bool	init()		= 0;
	virtual void	uninit()	= 0;
	virtual void	run()		= 0;
	
};

#endif