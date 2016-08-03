#include "OnlinePlayers.h"

int OnlinePlayers::OutTable(const std::string &Account, int &id) {
	int ret = -1;
	pthread_mutex_lock(&m_mutex);
	do {
		if(m_Player2TableMap.find(Account) == m_Player2TableMap.end()) {
			break;
		}
		if(m_onlinePlayMap.find(Account) == m_onlinePlayMap.end()) {
			if(GameConfig::debug > 1) {
				std::cerr << "no Account id:" << Account << std::endl;
			}
			break;
		}
		const Player *player = m_onlinePlayMap[Account];
		Table *table = m_Player2TableMap[Account];
		if(table->OutRoom(player) == -1) {
			break;
		}
		id = table->m_id;
		std::tr1::unordered_map<std::string, Table*>::iterator it = m_Player2TableMap.find(Account);
		m_Player2TableMap.erase(it);
		ret = 0;
	} while(0);
	pthread_mutex_unlock(&m_mutex);
	return ret;
}

int OnlinePlayers::InTable(const std::string &Account, int id) {
	int ret = -1;
	pthread_mutex_lock(&m_mutex);
	do {
		if(m_onlineTableMap.find(id) == m_onlineTableMap.end()) {
			LOG_DEBUG("%d table id error", id);
			break;
		}
		Table *table = m_onlineTableMap[id];
		if(m_onlinePlayMap.find(Account) == m_onlinePlayMap.end()) {
			LOG_DEBUG("%s account id error", Account.c_str());
			break;
		}
		if(m_Player2TableMap.find(Account) != m_Player2TableMap.end()) {
			LOG_DEBUG("%s account id has in table", Account.c_str());
			break;
		}
		const Player *player = m_onlinePlayMap[Account];
		table->InRoom(player);
		m_Player2TableMap[Account] = table;	//玩家游戏
		LOG_DEBUG("in InRoom OK");
		ret = 0;
	} while(0);
	pthread_mutex_unlock(&m_mutex);
	return ret;
}

int OnlinePlayers::CreateTable(const std::string &Account, int &id, const int &planPlay, const int &retCard) {
	int ret = -1;
	LOG_DEBUG("in CreateTable");
	pthread_mutex_lock(&m_mutex);
	id = COMMON::random(900000)+100000;
	while(m_onlineTableMap.find(id) != m_onlineTableMap.end()) {
		id ++;
	}
	do {
		//没有用户
		if(m_onlinePlayMap.find(Account) == m_onlinePlayMap.end()) {
			LOG_ALERT("%s uid error", Account.c_str());
			break;
		}
		const Player *player = m_onlinePlayMap[Account];
		int needRooms = planPlay/8;
		if(player->GetRoomCard() < needRooms) {
			break;
		}
		Table *table = new Table(player, 0, id, planPlay, retCard);
		m_onlineTableMap[id] = table;
		m_Player2TableMap[Account] = table;	//玩家游戏
		LOG_DEBUG("CreateTable OK");
		ret = 0;
	}while(0);
	pthread_mutex_unlock(&m_mutex);
	return ret;
}

int OnlinePlayers::DestroyTable(int id) {
	int ret = -1;
	pthread_mutex_lock(&m_mutex);
	do {
		if(m_onlineTableMap.find(id) == m_onlineTableMap.end()) {
			std::cerr << "no table id:" << id << std::endl;
			break;
		}

		Table *table = m_onlineTableMap[id];
		for(int i = 0; i < table->m_tablePlayer.size(); i ++) {
			const std::string &account = table->m_tablePlayer[i].m_player->m_account;
			std::tr1::unordered_map<std::string, Table*>::iterator it = m_Player2TableMap.find(account);
			if(it != m_Player2TableMap.end()) {
				m_Player2TableMap.erase(it);
			}
		}

		delete table;
		std::tr1::unordered_map<int, Table*>::iterator it = m_onlineTableMap.find(id);
		m_onlineTableMap.erase(id);
		ret = 0;
	} while(0);
	pthread_mutex_unlock(&m_mutex);
	return ret;
}

int OnlinePlayers::Register_Unlock(const std::string &Account, const std::string &Passwd, const std::string &Name) {
	//std::unique_lock<std::mutex> lck(m_mtx);
	int ret = 0;
	do {

		std::string sql = "select account, passwd from Player where account='"+Account+"' and passwd='"+Passwd+"';";
		std::vector<std::vector<std::string> > result;
		if(m_mysql.select(sql, result) == -1) {
			LOG_DEBUG("select error");
			ret = -1;
			break;
		}
		if(result.size() != 0) {
			LOG_DEBUG("account in mysql");
			ret = -1;
			break;
		}

		//sql = "insert into Player(account, passwd, name, roomCard) value ('"+Account+"', '"+Passwd+"', '"+Name+"', 100);";
		sql = "insert into Player(account, passwd, name, roomCard) value ('"+Account+"', '"+Passwd+"', 'yangshu', 100);";
		//std::cerr << m_mysql.insert(sql) << std::endl;
		if(m_mysql.insert(sql) == -1) {
			LOG_DEBUG("insert error");
			ret = -1;
			break;
		}
		std::cerr << sql << std::endl;
		LOG_DEBUG("sql = %s", sql.c_str());
		LOG_DEBUG("Register OK");
	} while(0);
	//lck.unlock();
	return ret;
}

int OnlinePlayers::Register(const std::string &Account, const std::string &Passwd) {
	//std::unique_lock<std::mutex> lck(m_mtx);
	int ret = 0;
	pthread_mutex_lock(&m_mutex);
	do {
		std::string sql = "select account, passwd from Player where account='"+Account+"' and passwd='"+Passwd+"';";
		std::vector<std::vector<std::string> > result;
		std::cerr << sql << std::endl;
		if(m_mysql.select(sql, result) == -1) {
			ret = -1;
			break;
		}
		LOG_DEBUG("sql = %s", sql.c_str());
		if(result.size() != 0) {
			ret = -1;
			break;
		}

		sql = "insert into Player(account, passwd, name) value ('"+Account+"', '"+Passwd+"', 'defualt');";
		LOG_DEBUG("sql = %s", sql.c_str());
		if(m_mysql.insert(sql) == -1) {
			ret = -1;
			break;
		}
	} while(0);

	pthread_mutex_unlock(&m_mutex);
	//lck.unlock();
	return ret;
}

int OnlinePlayers::Login(const std::string &Account, const std::string &Passwd, const std::string &Name) {
	int ret = 0;
	pthread_mutex_lock(&m_mutex);
	do {
		std::string sql = "select account, passwd, name, roomCard, playNum, id from Player where account='"+Account+"' and passwd='"+Passwd+"';";
		std::vector<std::vector<std::string> > result;
		m_mysql.select(sql, result);
		//如果没有注册的玩家立即注册
		if(result.size() == 0) {
			if(Register_Unlock(Account, Passwd, Name) == -1) {
				if(GameConfig::debug > 1) {
					std::cerr << "Register unlock fail" << std::endl;
				}
				ret = -1;
				break;
			}
			m_mysql.select(sql, result);
			if(result.size() == 0) {
				if(GameConfig::debug > 1) {
					std::cerr << "Register unlock fail" << std::endl;
				}
				ret = -1;
				break;
			}
		}

		if(m_onlinePlayMap.find(Account) != m_onlinePlayMap.end()) {
			ret = -1;
			break;
		}
		//Player *player = new Player(tt);
		Player *player = new Player(result[0]);
		m_onlinePlayMap[Account] = player;
	} while(0);
	pthread_mutex_unlock(&m_mutex);
	//lck.unlock();
	return ret;
}
int OnlinePlayers::Clear() {
	for(std::tr1::unordered_map<std::string, const Player*>::iterator it = m_onlinePlayMap.begin(); it != m_onlinePlayMap.end(); it ++) {
		delete it->second;
	}
	m_onlinePlayMap.clear();	//全部玩家
	for(std::tr1::unordered_map<int, Table*>::iterator it = m_onlineTableMap.begin(); it != m_onlineTableMap.end(); it ++) {
		delete it->second;
	}
	m_onlineTableMap.clear();
	m_Player2TableMap.clear();
	return 0;
}

int OnlinePlayers::show() const {
	//for(std::tr1::unordered_map<std::string, const Player*>::const_iterator it = m_onlinePlayMap.begin(); it != m_onlinePlayMap.end(); it ++) {
	//	(it->second)->show();
	//}
}
