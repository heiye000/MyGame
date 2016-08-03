#ifndef __PLAYER_H__
#define __PLAYER_H__

#include <vector>
#include <string>
#include "common/CommonFuc.h"
#include <iostream>

class Player {
public:
	Player(const std::vector<std::string> &Info);
public:
	void show() const;
	int GetRoomCard() const {
		return m_roomCard;
	}
public:
	std::string m_account;
	std::string m_name;
private:
	std::string m_passwd;
	int m_roomCard;
	int m_PlayNum;
	int m_id;
};

#endif
