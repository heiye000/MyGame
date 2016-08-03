#include "MySQLManager.h"

using namespace std;

int MySQLManager::insert(const std::string &sql) {
	if(!m_isConnected) {
		std::cerr << "MYSQL No Connected" << std::endl;
		return RUN_ERR;
	}
	if(sql.empty()) {
		std::cerr << "sql error:" << sql << std::endl;
		return RUN_ERR;
	}
	MYSQL_RES *res;
	MYSQL_ROW row;
	int ret = mysql_query(&m_mySQLClient, sql.c_str());
	if(ret < 0) {
		std::cerr << "Error Query: " << mysql_error(&m_mySQLClient) << std::endl;
		return RUN_ERR;
	}
	std::cerr << "sql = " << sql << std::endl;
	return ret;
}

int MySQLManager::select(const std::string &sql, std::vector<std::vector<std::string> > &result) {
	if(!m_isConnected) {
		std::cerr << "MYSQL No Connected" << std::endl;
		return RUN_ERR;
	}
	if(sql.empty()) {
		std::cerr << "sql error:" << sql << std::endl;
		return RUN_ERR;
	}
	MYSQL_RES *res;
	MYSQL_ROW row;
	int ret = mysql_query(&m_mySQLClient, sql.c_str());
	if(ret < 0) {
		std::cerr << "Error Query: " << mysql_error(&m_mySQLClient) << std::endl;
		return RUN_ERR;
	}
	std::vector<std::string> vrow;
	res = mysql_use_result(&m_mySQLClient);
	while((row = mysql_fetch_row(res))) {
		for(int i = 0; i < res->field_count; i ++) {
			vrow.push_back(row[i]);
		}
		result.push_back(vrow);
	}

	mysql_free_result(res);
	return RUN_OK;
}

MySQLManager::MySQLManager(const std::string &host, const std::string &userName, const std::string &password, const std::string &dbName, unsigned int port) {
	this->setHost(host);
	this->setUserName(userName);
	this->setPassword(password);
	this->setDBName(dbName);
	this->setPort(port);
	m_isConnected = false;
}

int MySQLManager::initConnection() {
	if(m_isConnected) {
		cerr << "Areadly Connect!" << endl;
		return RUN_OK;
	}
	mysql_init(&m_mySQLClient);
	if(!mysql_real_connect(&m_mySQLClient, m_host.c_str(), m_userName.c_str(), m_password.c_str(), m_dbName.c_str(), 0, NULL, 0)) {
		cerr << "[Connect to " << m_userName << " error: "<< mysql_error(&m_mySQLClient) << "]" << endl;
		return RUN_ERR;
	}
	if(mysql_set_character_set(&m_mySQLClient, "utf8")) {
		cerr << "[Set mysql characterset: " << mysql_error(&m_mySQLClient) << "]" << endl;
		return RUN_ERR;
	}
	m_isConnected = true;
	return RUN_OK;
}

MySQLManager::~MySQLManager() {
	this->destroyConnection();
}

int MySQLManager::destroyConnection() {
	if(m_isConnected) {
		mysql_close(&m_mySQLClient);
		m_isConnected = false;
	}
	return RUN_OK;
}
