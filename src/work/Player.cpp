#include "Player.h"

Player::Player(const std::vector<std::string> &Info) {
	m_account = Info[0];
	m_passwd = Info[1];
	m_name = Info[2];
	m_roomCard = COMMON::convert<std::string, int>(Info[3]);
	m_PlayNum = COMMON::convert<std::string, int>(Info[4]);
	m_id = COMMON::convert<std::string, int>(Info[5]);
}

void Player::show() const {
	std::cerr << "account = " << m_account
	<< "\npasswd = " << m_passwd
	<< "\nname = " << m_name
	<< "\nroomCard = " << m_roomCard 
	<< "\nPlayNum = " << m_PlayNum
	<< "\nid = " << m_id  << std::endl;
}

