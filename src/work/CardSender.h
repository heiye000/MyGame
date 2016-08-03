#ifndef __CARDSENDER_H__
#define __CARDSENDER_H__

#include "define.h"
#include "common/CommonFuc.h"

class CardSender {
public:
	virtual ~CardSender() {}
	virtual Pai getCard()=0;
	virtual int init()=0;
	virtual bool isLastOne()=0;
};

//发牌器
class CardSenderA:public CardSender {
public:
	int m_p;	//当前在什么位置
	Pai *m_card;	//麻将
public:
	CardSenderA() {
		m_card = new Pai[30];
	}
	~CardSenderA() {
		delete[] m_card;
		m_card = NULL;
	}
	virtual int init() {
		for(int i = 0; i < 30; i ++) {
			m_card[i] = 4;
		}
		m_p = 128;
	}
	virtual Pai getCard() {
		int pai = COMMON::random(27);
		while(m_card[pai] == 0) {
			pai ++;
			pai %= 27;
		}
		m_card[pai] --;
		m_p --;
	}
	virtual bool isLastOne() {
		if(m_p == 1) {
			return true;
		}
		return false;
	}
};

#endif