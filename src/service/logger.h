/****************************
Author:			屈天豪
date:			2016/7/30
Version:		v1.0
Descript:		日志包装类
Others:			日志的配置文件默认为 "./log4cpp.logConfig" , 如果没有找到，则默认输出目的地为 std::cout， 否则为配置文件中所指定的文件路径。
*****************************/
#ifndef LOGGER_H_
#define LOGGER_H_
#include"single.h"
#include <stdarg.h>
#include<vector>
namespace log4cpp
{
	class Category;
};

#define LOG_FATAL(msg, arg...)		__LOGGER__(Fatal, msg, ##arg)
#define LOG_ALERT(msg, arg...)		__LOGGER__(Alert, msg, ##arg)
#define LOG_CRIT(msg, arg...)		__LOGGER__(Crit, msg, ##arg)
#define LOG_ERROR(msg, arg...)		__LOGGER__(Error, msg, ##arg)
#define LOG_WARN(msg, arg...)		__LOGGER__(Warn, msg, ##arg)
#define LOG_NOTICE(msg, arg...)	__LOGGER__(Notice, msg, ##arg)
#define LOG_INFO(msg, arg...)		__LOGGER__(Info, msg, ##arg)
#define LOG_DEBUG(msg, arg...)		__LOGGER__(Debug, msg, ##arg)


#define __LOGGER__(out_level, msg, arg...) \
	CLogger::getInstance().out_level(msg, ##arg);

class  CLogger: public CSingle<CLogger>
{
	friend class CSingle<CLogger>;

public:	//输出不同级别的日志
	virtual void Fatal(const char* pszFormat, ...);
	virtual void Alert(const char* pszFormat, ...);
	virtual void Crit(const char* pszFormat, ...);
	virtual void Error(const char* pszFormat, ...);
	virtual void Warn(const char* pszFormat, ...);
	virtual void Notice(const char* pszFormat, ...);
	virtual void Info(const char* pszFormat, ...);
	virtual void Debug(const char* pszFormat, ...);

	int LoadConfig(const char* pszConfig);

public:
	virtual ~CLogger(void);
protected:
	CLogger(void);
	CLogger(const CLogger&);
	void operator=(const CLogger&);
private:
	std::vector<log4cpp::Category*> m_vCatogory;
};

#endif