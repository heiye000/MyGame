/****************************
Author:			屈天豪
Version:		v1.0
Descript:		基础框架
date:			2016/7/25
tips:			
		开启一个TCP服务器的步骤:
		1. 集成此框架， 在构造函数中显示初始化 CFrame
		2. 调用 main 运行框架
*****************************/

#ifndef SERVERFRAME_H_
#define SERVERFRAME_H_

#include "nocopyable.h"
#include "tcpInfo.h"

class SLoginInfo;

//错误事件
enum EnumError
{
	signal_quit = 0,
	socket_error,				//套接字错误
	socket_no_active,			//连接不活跃或者是死链接

};

class CFrame : private Nocopyable
{
public:
	CFrame(const char* pszName, short nPort);
	virtual ~CFrame(void);

	
	/*
		运行TCP框架
	*/
	void main();			


	/*
		框架初始化后会回调此接口， 你可以在继承类中实现此接口以初始化你的服务器
		返回值：
			true 表示你已经初始化完成， 框架可以开始运行
			false 表示你的初始化失败了，框架会调用你的 Uninitalize  然后结束运行
	*/
	virtual bool Initialize(void) = 0;




	/*
		框架正常退出后会回调此接口，你可以在继承类中实现此接口以清理你的服务器
	*/
	virtual void Uninitalize(void) = 0;



	/*
		当有客户端登录或者下线时，框架会回调此接口
		参数:
			pTCPHandle		连接处理接口的指针， 具体功能参照 iConnHandle.h 
			bLogin			true, 表示用户登录， false 表示用户下线
			SLoginInfo		登录信息，目前有对端的IP地址和端口号

	*/
	virtual void OnLogin(iTCPHandlePtr& pTCPHandle, bool bLogin, const SLoginInfo& loginInfo) = 0;

	

	/*
		当接收到客户端发送来的数据后，框架会回调此接口
		参数：
			pTCPHandle		发送数据的客户端连接接口
			msg				发送的具体信息
		
		注意： msg是一个二进制的buffer,你不能向对待字符串一样的对待他
	*/
	virtual void OnRecvMsg(iTCPHandlePtr& pTCPHandle, const std::string& msg) = 0;


	/*
		当发生任何错误后，框架会调用此接口
		参数:
			pTCPHandle		发送数据的客户端连接接口
			err_code		错误码
			pszError		错误信息
		备注：
			pTCPHandle 在某些错误发生时，你不能够正常的使用他
	*/
	virtual void OnError(iTCPHandlePtr& pTCPHandle, const EnumError& err_code, const char* pszError) = 0;



	/*
		框架接受到一个信号到来时 调用此接口
		参数：
			pEventHandle		信号接口， 具体功能请查看 iEvent.h

		备注:
		SIGINT   SIGQUIT SIGABRT SIGTERM  框架启动后默认接收这四个信号，不会通告给你， 默认的处理是 调用 Uninitalize 并安全结束程序
	*/
	virtual void OnSignal(iEventPtr& pEventHandle, void* params)	= 0;



	/*
		框架接受到一个定时器超时时 调用此接口
		参数:
			pEventHandle		定时器事件接口 具体功能请查看 iEvent.h
			params				你传递的参数
	*/
	virtual void OnTimer(iEventPtr& pEventHandle, void* params)		= 0;
protected:
	iTCPServerPtr	m_pServer;			//tcp服务器智能指针
private:
	bool Init();
	void unInit();
};


#endif