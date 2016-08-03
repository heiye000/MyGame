#ifndef __ONLINEPLAYER_H__
#define __ONLINEPLAYER_H__

#include <service/ServerFrame.h>
#include <string>
#include <vector>
#include <tr1/unordered_map>
#include <map>
#include "Player.h"
#include "GameConfig.h"
#include "common/MySQLManager.h"
#include "define.h"
#include "Table.h"

//登录注册模块
class OnlinePlayers {
public:
	static OnlinePlayers* getOnlinePlayers() {
		static OnlinePlayers onlinePlayers(GameConfig::db_addr, GameConfig::db_user, GameConfig::db_passwd, GameConfig::db_name);
		return &onlinePlayers;
	}
	//注册 ok
	int Register(const std::string &Account, const std::string &Passwd);
	//登录 ok
	int Login(const std::string &Account, const std::string &Passwd, const std::string &Name);
	//退出 
	int Logout(const std::string &Account);
	//创建房间
	int CreateTable(const std::string &Account, int &id, const int &planPlay, const int &retCard);
	//销毁房间
	int DestroyTable(int id);
	//加入房间
	int InTable(const std::string &Account, int id);
	//退出房间
	int OutTable(const std::string &Account, int &id);
	//得到牌桌
	Table* GetTable(const int &id) {
		if(m_onlineTableMap.find(id) == m_onlineTableMap.end()) {
			return NULL;
		}
		Table *table = m_onlineTableMap[id];
		return table;
	}
	Table* GetTable(const std::string &uid) {
		if(m_Player2TableMap.find(uid) == m_Player2TableMap.end()) {
			return NULL;
		}
		Table *table = m_Player2TableMap[uid];
		return table;
	}
	const Player* GetPlayer(const std::string &uid) {
		if(m_onlinePlayMap.find(uid) == m_onlinePlayMap.end()) {
			return NULL;
		}
		const Player *player = m_onlinePlayMap[uid];
		return player;
	}
	//清除
	int Clear();
	int show() const;
	~OnlinePlayers() {
		Clear();
		pthread_mutex_destroy(&m_mutex);
	}
private:
	int Register_Unlock(const std::string &Account, const std::string &Passwd, const std::string &Name);
	OnlinePlayers(const std::string &db_addr, const std::string &db_user, const std::string &db_passwd, const std::string &db_name):
	m_mysql(db_addr, db_user, db_passwd, db_name) {
		m_mysql.initConnection();
		pthread_mutex_init(&m_mutex, NULL);
	}
public:
	std::tr1::unordered_map<std::string, const Player*> m_onlinePlayMap;	//全部玩家
	std::tr1::unordered_map<int, Table*> m_onlineTableMap;	//全部牌桌
	std::tr1::unordered_map<std::string, Table*> m_Player2TableMap;	//玩家游戏
private:
	//std::map<std::string, const Player*> m_onlinePlayMap;	//全部玩家
	//std::vector<const Player *> m_onlinePlayList;		//全部在线玩家
	MySQLManager m_mysql;
	pthread_mutex_t m_mutex;							//互斥锁
};

#endif	
