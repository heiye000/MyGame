PROJECT (HELLO)

ADD_SUBDIRECTORY(src bin)


#include(CheckCXXCompilerFlag)
#CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
#CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
#if(COMPILER_SUPPORTS_CXX11)
#	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
#elseif(COMPILER_SUPPORTS_CXX0X)
#	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
#else()
#	message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
#endif()


#-pthread -L/usr/lib64/mysql -lmysqlclient
#target_link_libraries(-lmysqlclient)
#LINK_LIBRARIES(mysqlclient)
#SET(CMAKE_INSTALL_PREFIX /usr/local)
#SET(SRC_LIST main.cpp)
#MESSAGE(STATUS "This is BINARY dir " ${HELLO_BINARY_DIR})
#MESSAGE(STATUS "This is SOURCE dir "${HELLO_SOURCE_DIR})
#ADD_EXECUTABLE(hello ${SRC_LIST})

#ADD_SUBDIRECTORY(src bin)
