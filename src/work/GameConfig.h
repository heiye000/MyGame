#ifndef __GAMECONFIG_H__
#define __GAMECONFIG_H__

#include <string>
#include "common/MyConfig.h"

//############路径规划过程中使用的各种配置参数###############
class GameConfig {
public:
	static int Init();
public:
	static std::string db_addr;	//数据库地址
	static std::string db_passwd;	//数据库密码
	static std::string db_user;	//数据库帐号
	static std::string db_name;	//数据库名
	static int debug;
	static int listen_port;
};


#endif	//__ROUTECONFIG_H__
