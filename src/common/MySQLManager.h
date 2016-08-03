#ifndef __MYSQLMANAGER_H__
#define __MYSQLMANAGER_H__

#include <iostream>
#include <mysql/mysql.h>
#include <string>
#include <vector>
//#include "define.h"

#define RUN_ERR -1
#define RUN_OK 0

class MySQLManager {
public:
	int initConnection();
	int destroyConnection();
	int insert(const std::string &sql);
	int select(const std::string &sql, std::vector<std::vector<std::string> > &result);
	MySQLManager(const std::string &host, const std::string &userName, const std::string &password, const std::string &dbName, unsigned int port = 0);
	~MySQLManager();
public:
	void setHost(const std::string &host) {
		m_host = host;
	}
	void setUserName(const std::string &userName) {
		m_userName = userName;
	}
	void setPassword(const std::string &password) {
		m_password = password;
	}
	void setDBName(const std::string &dbName) {
		m_dbName = dbName;
	}
	void setPort(const int &port) {
		m_port = port;
	}
private:
	std::string m_host;
	std::string m_userName;
	std::string m_password;
	std::string m_dbName;
	MYSQL m_mySQLClient;
	int m_port;
	bool m_isConnected;
};


#endif //__MYSQLMANAGER_H__
