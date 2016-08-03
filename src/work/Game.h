#ifndef __GAME_H__
#define __GAME_H__

#include <service/ServerFrame.h>
#include <string>
#include <vector>
#include "Resp.h"

class Game {
public:
	//输入是用户uid 进行了commands 操作 resp是反馈给前段用户的数据
	static int doGame(std::string &uid, const std::string &commands, std::vector<Resp> &resp);
private:
	static int Register(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);		//注册
	static int Login(std::string &uid, const std::string &commands, std::vector<Resp> &resp);		//登录
	static int Logout(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);	//退出
	static int CreateTable(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);
	static int InRoom(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);
	static int OutRoom(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);
	static int PlayGame(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);
	static int Begin(const std::string &uid, const std::string &commands, std::vector<Resp> &resp);
};


#endif