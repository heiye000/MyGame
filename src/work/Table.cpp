#include "Player.h"
#include "define.h"
#include "Table.h"

int Table::toResp(const int &id, std::string &uid, std::string &resp) {
	if(m_status[id] == 0) {
		return -1;
	}
	uid = m_tablePlayers[id].m_player->m_account;
	resp = "waitchange:";
	resp += COMMON::convert<int, std::string>(m_planPlay)+"|"+
			COMMON::convert<int, std::string>(m_remain)+"|"+
			COMMON::convert<int, std::string>(m_people)+"|"+
			COMMON::convert<int, std::string>(id)+"|"+
			COMMON::convert<int, std::string>(m_roomMan)+"|"+
			COMMON::convert<int, std::string>(m_zhuang);
	for(int i = 0; i < 4; i ++) {
		resp += "|";
		if(m_status[i]) {
			resp += m_tablePlayers[i].m_player->m_name;
		}
	}
	return 0;
}

int Table::PlayerOperator(const Player *player, const std::string &type, const int card, const int card2) {
	if(m_tablePlayer[m_doingPlayer].m_player != player) {
		return -1;
	}

	if(type == "out") {
		m_tablePlayer[m_doingPlayer].m_playerCards.outCard(card);
	}
	else if(type == "gang") {
		m_tablePlayer[m_doingPlayer].m_playerCards.outCard(card);
		m_tablePlayer[m_doingPlayer].m_playerCards.gangCard(card2);
	}
	else if(type == "peng") {
		m_tablePlayer[m_doingPlayer].m_playerCards.outCard(card);
		m_tablePlayer[m_doingPlayer].m_playerCards.pengCard(card2);
	}
	else if(type == "angang") {
		m_tablePlayer[m_doingPlayer].m_playerCards.anGangCard(card2);
	}
	else if(type == "hu") {

	}
	else if(type == "guo") {

	}

	/*if(card != -1) {
		for(int i = 0; i < 3; i ++) {
			if()
		}
	}
	else {

	}*/

	m_doingPlayer = (m_doingPlayer+1)%4;
	return 0;
}

/*int Table::() {
	
}*/
/*
int Table::PlayerOperator() {
	if(type == "angang") {
		m_tablePlayer[m_doingPlayer].m_playerCards.outCard(card);
	}
	else if(type == "hu") {

	}
	else {
		PlayerOperator();
	}
}*/

int Table::GetPlayersAccount(std::vector<std::string> &playersID) {
	playersID.clear();
	for(int i = 0; i < m_tablePlayer.size(); i ++) {
		playersID.push_back(m_tablePlayer[i].m_player->m_account);
	}
	return 0;
}

int Table::InRoom(const Player *player) {
	if(m_people >= 4) {
		return -1;
	}
	for(int i = 0; i < 4; i ++) {
		if(m_status[i] == 0) {
			m_status[i] = 1;
			m_tablePlayers[i] = TablePlayer(player);
			m_people ++;
			break;
		}
	}
	return 0;
}

int Table::OutRoom(const Player *player) {
	int ret = -1;
	if(m_people <= 0) {
		return ret;
	}
	for(int i = 0; i < 4; i ++) {
		if(m_status[i]) {
			if(m_tablePlayers[i].m_player == player) {
				m_status[i] = 0;
				m_people --;
				ret = 0;
				break;
			}
		}
	}
	if(m_status[m_roomMan] == 0) {
		m_people = 0;
	}
	return ret;
}

int Table::GetPlayersID(std::string &players) {
	/*players = "";
	int num = 0;
	for(int i = 0; i < m_tablePlayer.size(); i ++) {
		if(i != 0) {
			players += "#";
		}
		num ++;
		players += m_tablePlayer[i].m_player->m_account;
	}
	while(num < 4) {
		players += "#";
		num ++;
	}*/
	return 0;
}

Table::~Table() {
	delete m_cardSender;
	//m_tablePlayer.clear();
}

	int m_id;			//牌桌id
	int m_planPlay;		//计划局数
	int m_tableType;			//属于什么游戏
	int m_retCard;		//扎马数

	std::vector<TablePlayer> m_tablePlayer;	//牌桌上的玩家
	int m_roomMan;		//房主

	TablePlayer m_tablePlayers[4];	//玩家
	int m_status[4];	//位置状态
	
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

Table::Table(const Player *player, const int type, const int &id, const int &planPlay, const int &retCard) {
	m_id = id;
	m_tableType = type;
	m_roomMan = 0;
	m_planPlay = planPlay;

	m_tablePlayers[0] = TablePlayer(player);
	m_status[0] = 1;
	for(int i = 1; i < 4; i ++) {
		m_status[i] = 0;
	}
	m_retCard = retCard;
	
	m_remain = planPlay;
	m_isPay = 0;
	m_tableStatus = 0;
	m_zhuang = 0;
	m_people = 1;

	m_doingPlayer = -1;
	prePlayer = -1;
	prePai = -1;
	m_cardSender = new CardSenderA();
}
/*Table::Table(const Player *player, const int type, const int id) {
	m_id = id;
	m_tableStatus = 0;
	m_tableType = type;
	m_zhuang = 0;
	m_doingPlayer = 0;
	m_cardSender = new CardSenderA();
	m_tablePlayer.push_back(TablePlayer(player));
}*/

int Table::BeginGame() {
	if(m_people != 4) {
		return -1;
	}
	m_tableStatus = 1;
	for(int i = 0; i < 4; i ++) {
		if(m_status[i]) {
			for(int j = 0; j < 13; j ++) {
				m_tablePlayers[i].addCard(m_cardSender->getCard());
			}
		}
	}
	Pai pai = m_cardSender->getCard();
	//m_playGame.Operator(m_tablePlayer[m_zhuang].m_playerCards, m_tablePlayer[m_zhuang].m_Operator, 0, pai);
	m_tablePlayers[m_zhuang].m_pai = pai;
	m_tablePlayers[m_zhuang].addCard(pai);
	return 0;
}

int Table::toClient(std::tr1::unordered_map<std::string, std::string> &playersOp) {
	/*for(int i = 0; i < m_tablePlayer.size(); i ++) {
		std::string Operator;
		if(i == m_doingPlayer) {
			m_tablePlayer[i].showLong(Operator);
		}
		else {
			m_tablePlayer[i].showShort(Operator);
		}

	}*/
	return 0;
}

int Table::GetAllCards(const int &id, std::string &uid, std::string &resp) {
	resp = "startgame:";
	std::string cards;
	m_tablePlayers[id].GetCard(uid, cards);
	resp += cards;
	return 0;
}
