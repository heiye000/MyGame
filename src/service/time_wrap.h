/****************************
Author:			屈天豪
date:			2016/8/1
Version:		v1.0
Descript:		一段时间的间隔包装 
Others:			
*****************************/
#ifndef TIME_WRAP_H_
#define TIME_WRAP_H_
#include <time.h>
#include <sys/time.h>

class qTime
{
	unsigned long long doNow()
	{
		unsigned long long retval = 0LL;
		struct timespec tv;
		clock_gettime(CLOCK_REALTIME, &tv);
		retval = tv.tv_sec;
		retval *= 1000LL;
		retval += (tv.tv_nsec / 1000000L);
		LOG_DEBUG("生成一个时间: %llu", retval);
		return retval;
	}

public:
	qTime()		
	{
		m_mesc = doNow();
	}

	qTime(const unsigned long long msec)
	{
		m_mesc = msec;
	}

	~qTime() {}

	/*qTime(const qTime& rhs)						{ m_mesc = rhs.m_mesc;}
	qTime& operator=(const qTime rhs)			{ m_mesc = rhs.m_mesc;}
	qTime& operator=(const unsigned long long mesc) { m_mesc = mesc;}*/

	qTime& operator+=(const qTime& rhs)			{ m_mesc += rhs.m_mesc; }

	/*
		获取秒数
	*/
	inline unsigned long sec() const
	{
		return m_mesc / 1000L;
	}


	
	/*
		支持  (unsigned long long )隐式转型
	*/
	inline operator unsigned long long ()
	{
		return m_mesc;
	}

	/*
		获取两个 qTime 之间的时间间隔（毫秒）
	*/
	inline const qTime timer(const qTime& rt) const
	{
		if (rt.m_mesc > m_mesc)
		{
			return qTime(rt.m_mesc - m_mesc);
		}
		else
		{
			return qTime(0LL);
		}
	}


private:
	unsigned long long m_mesc;					//总毫秒数
};


#endif