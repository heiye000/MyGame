#include "ServerFrame.h"
#include "tcpServer.h"
#include "tcpConn.h"

bool CFrame::Init()
{
	//初始化服务器
	bool err =	m_pServer->init();
	if (!err)
	{
		return false;
	}

	//框架初始化
	err = Initialize();
	if (!err)
	{
		return false;
	}
	
	return true;
}

CFrame::CFrame(const char* pszName, short nPort)
	: m_pServer(new CTCPServer(this, pszName, nPort))
{
}

CFrame::~CFrame( void )
{

}

void CFrame::unInit()
{
	Uninitalize();
	m_pServer->uninit();
}

void CFrame::main()
{
	if (Init())
	{
		m_pServer->run();
	}

	unInit();
}


