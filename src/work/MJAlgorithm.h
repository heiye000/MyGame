#ifndef __MJALGORITHM_H__
#define __MJALGORITHM_H__

#include "define.h"

#define HU 1
#define PENG 2
#define GANG 4
#define ANGANG 8
#define GUO 16

//int JIANG[] = {0,1,0,0,1,0,0,1,0, 0,1,0,0,1,0,0,1,0, 0,1,0,0,1,0,0,1,0};

class MJAlgorithm {
public:
	
public:
	virtual bool isHu(const PlayerCards &playerCards, const int type, const Pai pai)=0;
	virtual bool isGuo(const PlayerCards &playerCards, const int type, const Pai pai)=0;
	virtual bool isGang(const PlayerCards &playerCards, const int type, const Pai pai)=0;
	virtual bool isAnGang(const PlayerCards &playerCards, const int type, const Pai pai)=0;
	virtual bool isPeng(const PlayerCards &playerCards, const int type, const Pai pai)=0;
};

class GamePlayWay {
public:
	MJAlgorithm *m_alg;
public:
	int Operator(const PlayerCards &playerCards, int &Operator, const int type, const Pai pai) {
		Operator = 0;
		if(m_alg->isHu(playerCards, type, pai)) {
			Operator |= 1;
		}
		if(m_alg->isPeng(playerCards, type, pai)) {
			Operator |= 2;
		}
		if(m_alg->isGang(playerCards, type, pai)) {
			Operator |= 4;
		}
		if(m_alg->isAnGang(playerCards, type, pai)) {
			Operator |= 8;
		}
		if(m_alg->isGuo(playerCards, type, pai)) {
			Operator |= 16;
		}
		return 0;
	}
};

//平江麻将
class PingjiangMJ:public MJAlgorithm {
public:
	virtual bool isPeng(const PlayerCards &playerCards, const int type, const Pai pai) {
		//如果手上少于两张一样的牌，就不能碰
		if(playerCards.m_playCards[pai] < 2) {
			return false;
		}
		return true;
	}

	virtual bool isGang(const PlayerCards &playerCards, const int type, const Pai pai) {
		//如果手上摸到的
		if(type == 0) {
			for(int i = 0; i < playerCards.m_playCardsPeng.size(); i ++) {
				if(playerCards.m_playCardsPeng[i][0] == pai) {
					return true;
				}
			}
		}
		else if(type == 1) {
			if(playerCards.m_playCards[pai] != 3) {
				return false;
			}
		}
		return true;
	}

	virtual bool isGuo(const PlayerCards &playerCards, const int type, const Pai pai) {
		if(type == 0) {
			return false;
		}
		if(playerCards.m_size%3 == 1) {
			return true;
		}
		return false;
	}

	virtual bool isAnGang(const PlayerCards &playerCards, const int type, const Pai pai) {
		if(type == 0) {
			if(playerCards.m_playCards[pai] == 3) {
				return true;
			}
		}
		return false;
	}

	virtual bool isHu(const PlayerCards &playerCards, const int type, const Pai pai) {
		/*if(type == 0) {

		}
		else {
			Pai m_mj[30];
		int ret = 0;
		if(type == 1) {

		}
		else if(type == 0) {
			for(int i = 0; i < 27; i ++) {
				if(JIANG[i]) {
					memcpy(m_mj, playerCards.m_playCards, sizeof(playerCards.m_playCards));
					m_mj[pai] ++;
					ret = 0;
					if(m_mj[pai] >= 2) {
						ret += playerCards.m_playCardsPeng.size();
						ret += playerCards.m_playCardsGang.size();
						ret += playerCards.m_playCardsAnGang.size();
						m_mj[i] -= 2;
						if(Judge4X3(m_mj, ret)) {
							return true;
						}
					}
				}
			}
		}
			return false;
		}*/
		return true;
	}

	/*bool pengPengHu() {
		//先判断是否满足碰碰胡的基本条件
		int ret = 0;
		for(int i = 0; i < m_mjPublicCal.size(); i ++) {
			if(m_mjPublicCal[i].size() < 3) {
				continue;
			}
			//如果三个不一样，肯定不是砰砰胡
			if(m_mjPublicCal[i][0] != m_mjPublicCal[i][1]) {
				return false;
			}
			ret ++;
		}
		//将数据写入
		char tmp[15];
		memcpy(tmp, m_mjPrivateCal, sizeof(m_mjPrivateCal));

		for(int i = 0; i < 27; i ++) {
			if(tmp[i] == 3) {
				ret ++;
				tmp[i] -= 3;
			}
		}
		for(int i = 0; i < 27; i ++) {
			if(tmp[i] == 2) {
				ret ++;
				tmp[i] -= 2;
				break;
			}
		}
		if(ret != 5) {
			return false;
		}
		return true;
	}

	bool jiangJiangHu() {
		//碰碰胡的基础上才能将将胡
		if(pengPengHu()) {
			for(int i = 0; i < m_mjPublicCal.size(); i ++) {
				int flag = 0;
				for(int j = 0; j < m_JIANG.size(); j ++) {
					if(m_mjPublicCal[i][0] == m_JIANG[j]) {
						flag = 1;
						break;
					}
				}
				if(!flag) {
					return false;
				}
			}
			for(int i = 0; i < 27; i ++) {
				if(m_mjPrivateCal[i]) {
					int flag = 0;
					for(int j = 0; j < m_JIANG.size(); j ++) {
						if(m_JIANG[j] == m_mjPrivateCal[i]) {
							flag = 1;
							break;
						}
					}
					if(!flag) {
						return false;
					}
				}
			}
		}
		return true;
	}

	bool oneColer() {
		//胡牌的基础上才能清一色
		unsigned char Pai = m_mjPrivateCal[0];
		int flag = 0;
		if(Pai < 9) {
			flag = 0;
		}
		else if(Pai < 18) {
			flag = 1;
		}
		else {
			flag = 2;
		}
		unsigned char head = flag*9, tail = flag*9+9;
		for(int i = 0; i < 27; i ++) {
			if(m_mjPrivateCal[i]) {
				if(i < head || i >= tail) {
					return false;
				}
			}
		}
		for(int i = 0; i < m_mjPublicCal.size(); i ++) {
			if(i < m_mjPublicCal[i][0] || m_mjPublicCal[i][0] >= tail) {
				return false;
			}
		}
		return true;
	}

	bool serverDui() {
		char tmp[20];
		memset(tmp, m_mjPrivateCal, sizeof(m_mjPrivateCal));
		int ret = 0;
		for(int i = 0; i < 27; i ++) {
			while(tmp[i] >= 2) {
				tmp[i] -= 2;
				ret ++;
			}
		}
		if(ret != 7) {
			return false;
		}
		return true;
	}

	bool xiaoHu() {
		int flag = 0;
		for(int i = 0; i < m_JIANG.size(); i ++) {
			if(m_mjPrivateCal[m_JIANG[i]]) {
				flag = 1;
			}
		}
		if(gang()) {
			
		}
	}

	bool hu() {
		//砰砰胡 ok
		//将将胡
		//清一色
		//七小对
		//小胡
		//平胡
		if(Judge1()) {

		}
	}*/

private:
	/*bool isHuPai(const PlayerCards &playerCards, const int type, const int pai) {
		Pai m_mj[30];
		int ret = 0;
		if(type == 1) {

		}
		else if(type == 0) {
			for(int i = 0; i < 27; i ++) {
				if(JIANG[i]) {
					memcpy(m_mj, playerCards.m_playCards, sizeof(playerCards.m_playCards));
					m_mj[pai] ++;
					ret = 0;
					if(m_mj[pai] >= 2) {
						ret += playerCards.m_playCardsPeng.size();
						ret += playerCards.m_playCardsGang.size();
						ret += playerCards.m_playCardsAnGang.size();
						m_mj[i] -= 2;
						if(Judge4X3(m_mj, ret)) {
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	bool Judge4X3(Pai m_mj[], int ret) {
		//枚举每种花色
		for(int i = 0; i <= 18; i += 9) {
			//枚举是否可以组成3个
			for(int j = 0; j < 9; j ++) {
				if(m_mj[i+j] >= 3) {
					m_mj[i+j] -= 3;
					ret ++;
				}
				while(j+2<9 && m_mj[i+j] && m_mj[i+j+1] && m_mj[i+j+2]) {
					m_mj[i+j] --;
					m_mj[i+j+1] --;
					m_mj[i+j+2] --;
					ret ++;
				}
			}
		}
		if(ret != 4) {
			return false;
		}
		return true;
	}*/
};

#endif