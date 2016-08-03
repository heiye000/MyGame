#ifndef __TABLE_H__
#define __TABLE_H__

#include <string>
#include <vector>
#include <tr1/unordered_map>


#include "Player.h"
#include "define.h"
#include "TablePlayer.h"
#include "CardSender.h"
#include "MJAlgorithm.h"

//一桌游戏
class Table {
public:
	int m_id;			//牌桌id
	
	int m_tableType;			//属于什么游戏
	std::vector<TablePlayer> m_tablePlayer;	//牌桌上的玩家
	int m_roomMan;		//房主

	TablePlayer m_tablePlayers[4];	//玩家
	int m_status[4];	//位置状态
	int m_retCard;		//扎马数
	int m_planPlay;		//计划局数
	int m_remain;		//剩余游戏局数
	int m_isPay;		//是否付费
	int m_tableStatus;	//牌桌状态 0.等人 1.游戏中
	int m_zhuang;		//庄家
	int m_people;		//人数
	
	int m_doingPlayer;	//正在执行操作的玩家
	int prePlayer;		//上一个玩家
	Pai prePai;			//上一张打出的牌
	CardSender *m_cardSender;	//发牌器
	GamePlayWay m_playGame;	//游戏玩法
public:
	Table(const Player *player, const int type, const int &id, const int &planPlay, const int &retCard);
	~Table();
public:
	//玩家uid进行了 type操作 出了 card牌
	int PlayerOperator(const Player *player, const std::string &type, const int card, const int card2);
	int BeginGame();
	int GetPlayersID(std::string &players);
	int GetPlayersAccount(std::vector<std::string> &playersID);
	int InRoom(const Player *player);
	int OutRoom(const Player *player);
	int toClient(std::tr1::unordered_map<std::string, std::string> &playersOp);

	int toResp(const int &id, std::string &uid, std::string &resp);
	int GetAllCards(const int &id, std::string &uid, std::string &resp);
};

#endif
