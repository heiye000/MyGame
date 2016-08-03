#include "Game.h"
#include "OnlinePlayers.h"
#include "common/CommonFuc.h"
#include "GameConfig.h"

/*int Game::doGame(std::string &Account, const std::string &Commands, std::vector<Resp> Resp) {
	if(Opt == "login") {
		LogIn(Account, Command, Resp);
	}
	else if(Opt == "logout") {
		LogOut(Account, Command, Resp);
	}
	else if(Opt == "createroom") {
		CreateTable(Account, Command, Resp);
	}
	else if(Opt == "inroom") {
		InTable(Account, Command, Resp);
	}
	else if(Opt == "outroom") {
		OutTable(Account, Command, Resp);
	}
	else if(Opt == "game") {
		Play(Account, Command, Resp);
	}
	return 0;
}*/

//游戏模块
/*int Game::Play(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	int ret = -1;
	do {
		int pos = commands.find(":");
		if(pos == std::string::npos) {
			break;
		}
		std::string command = commands.substr(pos+1);
		pos = command.find(":");
		if(pos == std::string::npos) {
			break;
		}
		std::string Card = command.substr(pos+1);
		std::string type = command.substr(0, pos);
		pos = Card.find("|");
		int card = -1, card2 = -1;
		if(pos == std::string::npos) {
			card = COMMON::convert<std::string, int>(Card);
		}
		else {
			card = COMMON::convert<std::string, int>(Card.substr(0,pos));
			card2 = COMMON::convert<std::string, int>(Card.substr(pos+1));
		}
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		Table *table = onlinePlayer->GetTable(uid);
		const Player *player = onlinePlayer->GetPlayer(uid);
		table->PlayerOperator(player, type, card, card2);
		ret = 0;
	} while(0);
	
	std::tr1::unordered_map<std::string, std::string> playersOp;
	
	do {
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		Table *table = onlinePlayer->GetTable(uid);
		table->toClient(playersOp);
		std::tr1::unordered_map<std::string, std::string>::iterator it = playersOp.begin();
		Resp res;
		for(; it != playersOp.end(); it ++) {
			res.m_uid = it->first;
			res.m_resp = it->second;
			resp.push_back(res);
		}
	}while(0);
	
	return 0;
}*/

int Game::Begin(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
	Table *table = onlinePlayer->GetTable(uid);
	if(table->BeginGame()) {
		return -1;
	}

	Resp res;
	for(int i = 0; i < 4; i ++) {
		table->GetAllCards(i, res.m_uid, res.m_resp);
		resp.push_back(res);
	}	
	/*std::tr1::unordered_map<std::string, std::string> playersOp;
	table->toClient(playersOp);
	std::tr1::unordered_map<std::string, std::string>::iterator it = playersOp.begin();
	Resp res;
	for(; it != playersOp.end(); it ++) {
		res.m_uid = it->first;
		res.m_resp = it->second;
		resp.push_back(res);
	}*/
	return 0;
}

//房间模块
int Game::OutRoom(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	int ret = -1;
	int id;
	do {
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		if(onlinePlayer->OutTable(uid, id) == -1) {
			break;
		}
		ret = 0;
	} while(0);

	Resp res;
	do {
		if(ret == -1) {
			break;
		}
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		Table *table = onlinePlayer->GetTable(id);
		if(table == NULL) {
			ret = -1;
			break;
		}
		for(int i = 0; i < 4; i ++) {
			if(table->toResp(i, res.m_uid, res.m_resp) != -1) {
				resp.push_back(res);
			}
		}
		if(table->m_roomMan == 0) {
			if(GameConfig::debug > 1) {
				std::cerr << "DestroyTable:" << table->m_id << std::endl;
			}
			onlinePlayer->DestroyTable(id);
			id = -1;
		}
	} while(0);
	if(ret == -1) {
		res.m_resp = "outroom:no";
		res.m_uid = uid;
		resp.push_back(res);
	}
	return ret;
}

int Game::InRoom(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	//inroom:xxxxxx    xxxx是房间号码
	LOG_DEBUG("in InRoom");
	int ret = -1;
	int id;
	do {
		id = COMMON::convert<std::string, int>(commands);
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		if(onlinePlayer->InTable(uid, id) == -1) {
			break;
		}
		ret = 0;
	} while(0);

	Resp res;
	do {
		if(ret == -1) {
			break;
		}
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		Table *table = onlinePlayer->GetTable(id);
		if(table == NULL) {
			ret = -1;
			break;
		}
		res.m_resp = "inroom:yes";
		res.m_uid = uid;
		resp.push_back(res);
		for(int i = 0; i < 4; i ++) {
			if(table->toResp(i, res.m_uid, res.m_resp) != -1) {
				resp.push_back(res);
			}
		}
		//table->GetPlayersID(players);
		//std::vector<std::string> playerID;
		//table->GetPlayersAccount(playerID);
		//for(int i = 0; i < playerID.size(); i ++) {
		//	res.m_uid = playerID[i];
		//	res.m_resp = "inroom:"+COMMON::convert<int, std::string>(i)+"|"+COMMON::convert<int, std::string>(playerID.size())+"#+"+COMMON::convert<int, std::string>(id)+"#"+players;
		//	resp.push_back(res);
		//}
	} while(0);
	if(ret == -1) {
		res.m_resp = "inroom:no";
		res.m_uid = uid;
		resp.push_back(res);
	}
	return 0;
}

int Game::CreateTable(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	int ret = -1;
	std::cerr << "in CreateTable Game" << std::endl;
	int id;
	do {
		std::vector<std::string> Info;
		COMMON::sepString(commands, "|", Info);
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		const Player *player = onlinePlayer->GetPlayer(uid);

		if(onlinePlayer->CreateTable(uid, id, COMMON::convert<std::string, int>(Info[0]), COMMON::convert<std::string, int>(Info[1])) == -1) {
			break;
		}
		ret = 0;
	} while(0);

	Resp res;
	do {
		if(ret == -1) {
			break;
		}
		res.m_resp = "createroom:yes|"+COMMON::convert<int, std::string>(id);
	} while(0);
	if(ret == -1) {
		res.m_resp = "inroom:no";
	}
	res.m_uid = uid;
	resp.push_back(res);
	return ret;
}

int Game::doGame(std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	if(GameConfig::debug > 1) {
		std::cerr << "in DoGame" << std::endl;
	}
	int pos = commands.find(":");
	if(pos == std::string::npos) {
		return -1;
	}
	std::string command = commands.substr(pos+1);
	std::string Opt = commands.substr(0, pos);
	if(Opt == "reg") {
		Game::Register(uid, command, resp);
	}
	else if(Opt == "login") {
		Game::Login(uid, command, resp);
	}
	else if(Opt == "logout") {
		Game::Logout(uid, command, resp);
	}
	else if(Opt == "inroom") {
		Game::InRoom(uid, command, resp);
	}
	else if(Opt == "createroom") {
		Game::CreateTable(uid, command, resp);
	}
	else if(Opt == "outroom") {
		Game::OutRoom(uid, command, resp);
	}
	else if(commands.find("begin") != std::string::npos) {
		Game::Begin(uid, commands, resp);	//开始游戏
	}
	/*else if(commands.find("end") != std::string::npos) {
		//Game::End();	//结束游戏
	}
	
	else if(commands.find("play") != std::string::npos) {
		Game::PlayGame(uid, commands, resp);	//玩游戏
	}
	else if(commands.find("speek") != std::string::npos) {

	}*/
}



int Game::Register(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	//reg:account|xxxxx#passwd|yyyyyy    xxx是帐号 yyyy是密码
	if(GameConfig::debug > 1) {
		std::cerr << "in Register" << std::endl;
	}
	int ret = -1;
	do {
		std::vector<std::string> Info;
		COMMON::sepString(commands, "|", Info);
		if(Info.size() != 2) {
			break;
		}
		std::string account = Info[0];
		std::string passwd = Info[1];
		if(GameConfig::debug > 1) {
			std::cerr << "account = " << account << " passwd = " << passwd << std::endl;
		}
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		if(onlinePlayer->Register(account, passwd) == -1) {
			break;
		}
		ret = 0;
	}while(0);
	Resp res;
	if(ret == 0) {
		res.m_resp = "reg:ok";
		res.m_uid = uid;
	}
	else {
		res.m_resp = "reg:no";
		res.m_uid = uid;
	}
	resp.push_back(res);
	return ret;
}

int Game::Login(std::string &uid, const std::string &commands, std::vector<Resp> &resp) {
	LOG_DEBUG("in Login");
	int ret = -1;
	Resp res;
	do {
		std::vector<std::string> Info;
		COMMON::sepString(commands, "|", Info);
		if(Info.size() != 2) {
			LOG_ALERT("%s commands error", commands.c_str());
			break;
		}
		std::string account = Info[0];
		std::string name = Info[1];
		std::string passwd = "1";
		OnlinePlayers *onlinePlayer = OnlinePlayers::getOnlinePlayers();
		if(GameConfig::debug > 1) {
			std::cerr << "account = " << account << " passwd = " << passwd << " name = " << name << std::endl;
		}
		if(onlinePlayer->Login(account, passwd, name) == -1) {
			break;
		}
		const Player *player = onlinePlayer->GetPlayer(account);
		ret = 0;
		uid = account;
		res.m_resp = "login:yes|"+COMMON::convert<int, std::string>(player->GetRoomCard());
	} while(0);
	
	if(ret == -1) {
		res.m_resp = "login:no";
	}
	res.m_uid = uid;
	resp.push_back(res);
	return ret;
}

int Game::Logout(const std::string &uid, const std::string &commands, std::vector<Resp> &resp) {

	return 0;
}
