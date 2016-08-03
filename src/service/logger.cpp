#include "logger.h"

#include "log4cpp/Category.hh"
#include "log4cpp/PropertyConfigurator.hh"
#include "log4cpp//FileAppender.hh"
#include "log4cpp/OstreamAppender.hh"
#include "log4cpp/PatternLayout.hh"

#define XDN_LOG(PRIO)\
	va_list paramList;\
	va_start(paramList, pszFormat);\
	m_vCatogory[PRIO / 100]->logva(PRIO, pszFormat, paramList);\
	va_end(paramList);

using namespace log4cpp;

CLogger::CLogger( void )
{
	m_vCatogory.resize(8);
	LoadConfig("./log4cpp.logConfig");
}

CLogger::~CLogger( void )
{
	Category::shutdown();
}
#include<iostream>
using namespace std;
int CLogger::LoadConfig( const char* pszConfig )
{
	Category::shutdown();

	try
	{
		log4cpp::PropertyConfigurator::configure(pszConfig);
		m_vCatogory[Priority::FATAL] = &Category::getInstance("fatalCategory");
		m_vCatogory[Priority::ALERT / 100] = &Category::getInstance("alertCategory");
		m_vCatogory[Priority::CRIT / 100] =  &Category::getInstance("critCategory");
		m_vCatogory[Priority::ERROR / 100] = &Category::getInstance("errorCategory");
		m_vCatogory[Priority::WARN / 100] = &Category::getInstance("warnCategory");
		m_vCatogory[Priority::NOTICE / 100] = &Category::getInstance("noticeCategory");
		m_vCatogory[Priority::INFO / 100] = &Category::getInstance("infoCategory");
		m_vCatogory[Priority::DEBUG / 100] = &Category::getInstance("debugCategory");
	}
	catch(log4cpp::ConfigureFailure&)
	{
		//配置读取出现异常(配置文件不存在也会执行这里)
		log4cpp::OstreamAppender* pAppender = new log4cpp::OstreamAppender("rootAppender", &std::cout);
		log4cpp::PatternLayout* pLayout = new log4cpp::PatternLayout();
		pLayout->setConversionPattern("%d [%p] - %m%n");
		pAppender->setLayout(pLayout);

		Category& root = log4cpp::Category::getRoot();
		root.addAppender(pAppender);
		root.setPriority(log4cpp::Priority::DEBUG);

		for (std::vector<log4cpp::Category*>::iterator it = m_vCatogory.begin(); it != m_vCatogory.end(); ++it)
		{
			(*it) = &root;
		}

	}

	Category* pCategory = &log4cpp::Category::getRoot();
	log4cpp::Appender* pAppender = pCategory->getAppender();
	size_t nIndex = 0;

	while (nIndex < m_vCatogory.size())
	{
		if ((pAppender != NULL) && (!pAppender->reopen()))
		{

			pCategory->removeAppender(pAppender);
		}

		pCategory = m_vCatogory[nIndex];
		pAppender = pCategory->getAppender();
		++nIndex;
	}
	return 0;
}

void CLogger::Fatal( const char* pszFormat, ... )
{
	XDN_LOG(Priority::FATAL);
}

void CLogger::Alert( const char* pszFormat, ... )
{
	XDN_LOG(Priority::ALERT);
}

void CLogger::Crit( const char* pszFormat, ... )
{
	XDN_LOG(Priority::CRIT);
}

void CLogger::Error( const char* pszFormat, ... )
{
	XDN_LOG(Priority::ERROR);
}

void CLogger::Warn( const char* pszFormat, ... )
{
	XDN_LOG(Priority::WARN);
}

void CLogger::Notice( const char* pszFormat, ... )
{
	XDN_LOG(Priority::NOTICE);
}

void CLogger::Info( const char* pszFormat, ... )
{
	XDN_LOG(Priority::INFO);
}

void CLogger::Debug( const char* pszFormat, ... )
{
	XDN_LOG(Priority::DEBUG);
}
