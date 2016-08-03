#include "define.h"

int PlayerCards::getCard(std::string &resp) {
	for(int i = 0; i < 27; i ++) {
		for(int j = 0; j < m_playCards[i]; j ++) {
			if(i > 17) {
				resp += COMMON::convert<int, std::string>(i+13);
			}
			else if(i > 8) {
				resp += COMMON::convert<int, std::string>(i+12);
			}
			else {
				resp += COMMON::convert<int, std::string>(i+11);
			}
		}
	}
	return 0;
}

int PlayerCards::addCard(Pai idx) {
	m_size ++;
	m_playCards[idx] ++;
	return 0;
}

int PlayerCards::outCard(Pai idx) {
	m_size --;
	m_playCards[idx] --;
	return 0;
}


int PlayerCards::pengCard(Pai idx) {
	m_size -= 2;
	m_playCards[idx] -= 2;
	std::vector<Pai> peng;
	for(int i = 0; i < 3; i ++) {
		peng.push_back(idx);
	}
	m_playCardsPeng.push_back(peng);
	return 0;
}

int PlayerCards::gangCard(Pai idx) {
	if(m_playCards[idx] == 3) {
		m_size -= 3;
		m_playCards[idx] -= 3;
		std::vector<Pai> gang;
		for(int i = 0; i < 4; i ++) {
			gang.push_back(idx);
		}
		m_playCardsGang.push_back(gang);
	}
	else {
		m_size -= 1;
		m_playCards[idx] -= 1;
		std::vector<Pai> gang;
		for(int i = 0; i < 4; i ++) {
			gang.push_back(idx);
		}
		m_playCardsGang.push_back(gang);
		std::vector<std::vector<Pai> >::iterator it = m_playCardsPeng.begin();
		for(; it != m_playCardsPeng.end(); it ++) {
			if((*it)[0] == idx) {
				m_playCardsPeng.erase(it);
				break;
			}
		}
	}
	return 0;
}

int PlayerCards::anGangCard(Pai idx) {
	m_size -= 4;
	m_playCards[idx] -= 4;
	std::vector<Pai> gang;
	for(int i = 0; i < 4; i ++) {
		gang.push_back(idx);
	}
	m_playCardsGang.push_back(gang);
	return 0;
}

int PlayerCards::showPublic(std::string &resp) {
	resp = "";
	bool flag = 0;
	for(int i = 0; i < m_playCardsPeng.size(); i ++) {
		if(flag) {
			resp += "|";
		}
		flag = true;
		for(int j = 0; j < m_playCardsPeng[i].size(); j ++) {
			resp += char(m_playCardsPeng[i][j]);
		}
	}
	for(int i = 0; i < m_playCardsGang.size(); i ++) {
		if(flag) {
			resp += "|";
		}
		flag = true;
		for(int j = 0; j < m_playCardsGang[i].size(); j ++) {
			resp += char(m_playCardsGang[i][j]);
		}
	}
	for(int i = 0; i < m_playCardsAnGang.size(); i ++) {
		if(flag) {
			resp += "|";
		}
		flag = true;
		for(int j = 0; j < m_playCardsAnGang[i].size(); j ++) {
			resp += char(m_playCardsAnGang[i][j]);
		}
	}
	return 0;
}

int PlayerCards::showPrivate(std::string &resp) {
	for(int i = 0; i < 27; i ++) {
		if(m_playCards[i]) {
			for(int j = 0; j < m_playCards[i]; j ++) {
				resp += char(i+(int('@')));
			}
		}
	}
	return 0;
}
