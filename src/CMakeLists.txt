INCLUDE_DIRECTORIES(/root/qutianhao/MyGame/src)
link_directories(/usr/lib64/mysql)
#add_definitions("-std=c++11")
#include_directories(/usr/lib64/mysql)
SET(SRC_LIST main.cpp
#	work/add.cpp
#	work/sub.hpp

	json/json_value.cpp
	json/json_writer.cpp
	json/json_reader.cpp

	common/MySQLManager.cpp
//	common/mythreadpool.cpp
//	common/socketServer.cpp
//	common/sockLinker.cpp
//	common/define.h
	common/CommonFuc.cpp
	common/MyConfig.cpp

	work/GameConfig.cpp
	work/OnlinePlayers.cpp
	work/Player.cpp
	work/CardSender.cpp
	work/define.cpp
	work/Game.cpp
	work/MJAlgorithm.cpp
	work/Table.cpp
	work/TablePlayer.cpp
	work/Resp.h

#	common/myMempool.cpp
#	common/sockClient.cpp
#	common/myalgorithm.cpp
#	common/mycommonfuc.cpp
#	common/mymatrix.cpp
	
#	modify by qutianhao
	service/nocopyable.h
	service/single.h
#	service/typeManip.h
	service/SmartPtr.h
	service/tcpInfo.h
	service/ServerFrame.cpp
	service/tcpConn.cpp
	service/tcpServer.cpp
	service/Event.cpp
	service/timeEvent.cpp
	service/logger.cpp
	service/time_wrap.h
	)

ADD_EXECUTABLE(test ${SRC_LIST})

#include_directories(/usr/lib64/mysql)
TARGET_LINK_LIBRARIES(test pthread)
TARGET_LINK_LIBRARIES(test mysqlclient)
TARGET_LINK_LIBRARIES(test event)
TARGET_LINK_LIBRARIES(test log4cpp)
