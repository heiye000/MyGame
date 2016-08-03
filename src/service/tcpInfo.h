#ifndef TCPINFO_H_
#define TCPINFO_H_
#include "SmartPtr.h"
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//公用头文件
#include <string>
#include<iostream>
#include<assert.h>
#include<set>
#include<map>
#include<vector>
#include<list>
#include<algorithm>

#include "iServer.h"
#include "iEvent.h"
#include "iConnHandle.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//登录信息
struct SLoginInfo
{
	std::string strLoginIP;			//对端登录IP
	short  nRemotePort;		//对端登录端口
	std::string strExtra;			//验证信息
};


//死亡检测信息
class CDeadCheck
{
public:
	explicit CDeadCheck(unsigned long __interval)
	{
		set_interval(__interval);
	}

	inline void reset()
	{
		start_pos = 0;
	}

	inline void next()
	{
		start_pos += block_size;
	}

	const inline unsigned int pos() const
	{
		return start_pos;
	}


	const inline unsigned int block() const
	{
		return block_size;
	}

	//秒
	const inline unsigned long total_time_sec() const
	{
		return m_total_time;
	}

	inline void set_interval(unsigned long __interval)
	{
		m_total_time = __interval;
		evenytime_interval = __interval / 10;
		start_pos = 0;
		block_size = 200;
	}

	const inline unsigned int GetTime() const
	{
		return evenytime_interval;
	}

private:
	unsigned long m_total_time;
	unsigned int evenytime_interval;	//每次检查间隔时间
	unsigned int  start_pos;			//开始检测的为止
	unsigned int  block_size;			//每次检测的连接数量 （固定200 个）

};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
#include "logger.h"

////日志声明
//#define DEBUG		
//#define INFO	
//#define ALTER
//#define ERROR
//
//#include<stdio.h>
//
//#ifdef DEBUG
//#define	LOG_DEBUG(msg, arg...) printf("[DEBUG]"msg"\n", ##arg);
//#else
//#define	LOG_DEBUG
//#endif //end DEBUG
//
//#ifdef INFO
//#define LOG_INFO(msg, arg...) printf("[INFO]"msg"\n", ##arg);
//#else
//#define LOG_INFO
//#endif
//
//#ifdef ALTER
//#define LOG_ALTER(msg, arg...) printf("[ALTER]"msg"\n", ##arg);
//#else
//#define LOG_ALTER
//#endif
//
//#ifdef ERROR
//#define LOG_ERROR(msg, arg...) printf("[ERROR]"msg"\n", ##arg);
//#else
//#define LOG_ERROR
//#endif

/////////////////////////////////////////////////////////////////////////////////////////////////////////////






/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//短式声明
class CTCPHandle;
class CTCPServer;
class CFrame;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////





/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//智能指针声明
typedef		qth::SmartPtr<SLoginInfo>																LoginInfoPtr;//tcp登录信息的智能处理类
typedef		qth::SmartPtr<iConnHandle>																iTCPHandlePtr;//tcp处理器的智能指针类
typedef		qth::SmartPtr<iServer>																	iTCPServerPtr;//tcp服务器智能指针
typedef		qth::SmartPtr<iEvent>																	iEventPtr;	//事件智能指针
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////



#endif// end tcpInfo.h