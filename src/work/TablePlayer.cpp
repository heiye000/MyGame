#include "TablePlayer.h"

int TablePlayer::GetCard(std::string &uid, std::string &resp) {
	uid = m_player->m_account;
	return m_playerCards.getCard(resp);
}

int TablePlayer::addCard(Pai idx) {
	return m_playerCards.addCard(idx);
}

int TablePlayer::outCard(Pai idx) {
	return m_playerCards.outCard(idx);
}


int TablePlayer::pengCard(Pai idx) {
	return m_playerCards.pengCard(idx);
}

int TablePlayer::gangCard(Pai idx) {
	return m_playerCards.gangCard(idx);
}

int TablePlayer::anGangCard(Pai idx) {
	return m_playerCards.anGangCard(idx);
}

int TablePlayer::showLong(std::string &resp) {
	std::string privatePai;
	m_playerCards.showPrivate(privatePai);
	std::string publicPai;
	m_playerCards.showPublic(publicPai);
	resp = privatePai+"#"+publicPai;
	return 0;
}

int TablePlayer::showShort(std::string &resp) {
	std::string privatePai = COMMON::convert<int, std::string>(m_playerCards.m_size);
	std::string publicPai;
	m_playerCards.showPublic(privatePai);
	resp = privatePai+"#"+publicPai;
	return 0;
}
