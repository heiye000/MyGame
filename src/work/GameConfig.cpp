#include "GameConfig.h"

std::string GameConfig::db_addr;	//数据库地址
std::string GameConfig::db_passwd;	//数据库密码
std::string GameConfig::db_user;	//数据库帐号
std::string GameConfig::db_name;	//数据库名
int GameConfig::debug;
int GameConfig::listen_port;

int GameConfig::Init() {
	/*路径规划内部参数*/
	db_addr = MyConfig::getString("db_addr");
	db_passwd = MyConfig::getString("db_passwd");
	db_user = MyConfig::getString("db_user");
	db_name = MyConfig::getString("db_name");
	debug = MyConfig::getInt("debug");
	listen_port = MyConfig::getInt("listen_port");
	return 0;
}
