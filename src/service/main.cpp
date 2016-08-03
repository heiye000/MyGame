#include<iostream>
using namespace std;
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<string>
#include<set>
#include<service/ServerFrame.h>
#include<tr1/unordered_map>

struct CMyFrame: public CFrame
{
// 框架必须显示构造其基类，  传递 服务名称， 监听的端口
	CMyFrame(): CFrame("haha", 1314){}
	/////////////////////////////////////////////////////////////////////////
	//初始化
	virtual bool Initialize(void)
	{ 
		static char buf[]= "hello signal!";
		static char buf1[] = "hello Timer 1";
		static char buf3[] = "hello Timer 3";

		//m_pServer->AddSignal(20, (void*)buf); // ctrl-z 信号
			
	//	struct	timeval  ti = {1, 0};  //3秒一次的定时器
	//	struct	timeval  ti2 = {3, 0};  //1秒一次的定时器
	//	m_pServer->SetTimer(100, ti, (void*)buf1);
	//	m_pServer->SetTimer(103, ti2, (void*)buf3);
	
	//设置死连接检测时间
	m_pServer->SetDeadCheck(60*10);
		return true;
	
	}
//////////////////////////////////////////////////////////////////////////////////////
//
//

//////////////////////////////////////////////////////////////////////
///反初始化
	virtual void Uninitalize(void)
	{
		//m_handles.clear(); //释放所有的客户端连接

		//m_pServer->FreeSignal(20); //释放信号

		//m_pServer->KillTimer(100);//释放定时器
		//m_pServer->KillTimer(103);
	}

////////////////////////////////////////////////////////////////////////////////////////////////////
//登录、下线
	virtual void OnLogin(iTCPHandlePtr& pTCPHandle, bool bLogin, const SLoginInfo& loginInfo)
	{
		if(bLogin)
		{
			std::string str("well come to heiye chat!");
			
			cout << "CMyFrame::OnLogin 有客户端登录服务器 ip = " << loginInfo.strLoginIP.c_str() << "port = " << loginInfo.nRemotePort << endl;
			pTCPHandle->SendMsg(str.c_str(), str.size());
			m_handles.insert(pTCPHandle); //保存这个连接

		}
		else
		{
			cout << "CMyFrame::OnLogin 有客户端断开连接 ip = " << loginInfo.strLoginIP.c_str() << "port = " << loginInfo.nRemotePort << endl;
			m_handles.erase(pTCPHandle); //释放这个链接,如果你不释放这个链接， 框架不会再次通知你， 这个链接将一直持续到你释放他的一段时间后
		}
	}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

////////////////////////////////////////////////////////////////////////////////////////////////////
//接受消息
	virtual void OnRecvMsg(iTCPHandlePtr& pTCPHandle, const std::string& msg)
	{
/*
		static int num = 0;
		static int num2 = 0;
		++num; 
		++num2;

		if (num2 > 1000)
		{
			LOG_DEBUG("test");
			num2 = 0;
		}
*/
			std::string stringWho = pTCPHandle->GetPeerAddress().strLoginIP;
		
	//	LOG_DEBUG("recv = %s", msg.c_str());

		for (std::set<iTCPHandlePtr>::iterator it = m_handles.begin(); it != m_handles.end(); ++it)
		{
			
			//std::string temp = stringWho + " say: " + msg.c_str();
			//遍历所有链接
			(*it)->SendMsg(msg.c_str(), msg.size()); //将消息发送给所有客户端
		}
	}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//连接、套接字、事件、服务等错误处理
	virtual void OnError(iTCPHandlePtr& pTCPHandle, const EnumError& err_code, const char* pszError)
	{
		//std::cout << "错误" << std::endl; 
		//
		//
	
		if (socket_no_active == err_code)
		{
			//处理非活跃连接
			cout << "非活跃连接 %s" << pTCPHandle->GetPeerAddress().strLoginIP.c_str() << endl;
		}

		m_handles.erase(pTCPHandle); //在大多数的套接字错误情况下，你都应该释放这个连接
	}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//信号处
	virtual void OnSignal(iEventPtr& pEventHandle, void* params)
	{
		cout << "recv Signal" << pEventHandle->GetEventId() << ", params = " << (char*)params << endl;
		
		if (std::string((const char*)params) ==  "hello signal!")
		{
			static char buf[] = "hello two signal!";
			struct timeval t;
			pEventHandle->SetEvent(20,t, (void*)buf);  //重新设定信号的参数二，你不能改变这个信号编码（即第一个参数）
		}
		else
		{
			m_pServer->FreeSignal(20); //手动释放信号， 你无法释放框架默认接收的四个信号
		}
	}

	virtual void OnTimer(iEventPtr& pEventHandle, void* params)
	{
		//cout << "定时器到: " << pEventHandle->GetEventId() << ", params = " << (char*)params << endl;
	
	}



	std::set<iTCPHandlePtr> m_handles;
};


int main(int argc, char* argv[])
{
//	sleep(10);
	CMyFrame f;
	f.main();
//	LOG_DEBUG("测试日志文件");
	return 0;
	
}



