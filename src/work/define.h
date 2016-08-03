#ifndef __DEFINE_H__
#define __DEFINE_H__

#include <string>
#include <vector>
#include <string.h>
#include <common/CommonFuc.h>

typedef int Pai;
typedef int PlayStatus;

//玩家手牌
class PlayerCards {
public:
	std::vector<std::vector<Pai> > m_playCardsPeng;	//碰的牌
	std::vector<std::vector<Pai> > m_playCardsGang;	//杠的牌
	std::vector<std::vector<Pai> > m_playCardsAnGang;	//暗杠的牌
	Pai m_playCards[27];	//手牌
	int m_size;				//手牌数目
public:
	PlayerCards() {
		memset(m_playCards, 0, sizeof(m_playCards));
		m_size = 0;
	}
	int getCard(std::string &resp);
	//出牌
	int outCard(Pai idx);
	//摸牌
	int addCard(Pai idx);
	//碰
	int pengCard(Pai idx);
	//杠
	int gangCard(Pai idx);
	//暗杠
	int anGangCard(Pai idx);
	//胡
	int huCard();
	//显示私有部分
	int showPublic(std::string &resp);
	//显示公有部分
	int showPrivate(std::string &resp);
};

#endif