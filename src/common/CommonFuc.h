#ifndef __COMMON_FUNC_H__
#define __COMMON_FUNC_H__

#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <fstream>
#include <sys/time.h>
#include <stdarg.h>
#include <iomanip>



#define MAXLOGLEN 204800

namespace COMMON
{
//时间转换
const int mon_day[]={31,28,31,30,31,30,31,31,30,31,30,31};
//用来计时的类
class MYTimer{
private:
	struct timeval _b;
	struct timeval _e;
public:
	MYTimer(){
		gettimeofday(&_b,NULL);
	}
	void start(){
		gettimeofday(&_b,NULL);
	};
	int cost(){
		gettimeofday(&_e,NULL);
		return (_e.tv_sec-_b.tv_sec)*1000000+(_e.tv_usec-_b.tv_usec);
	}
};

template<class InT,class OutT>
OutT convert(const InT& inValue){
	std::stringstream ss;
	ss<<inValue;
	OutT res;
	ss>>res;
	return res;
}

//将字符串切割为数组
void sepString(std::string input, const std::string& sep,std::vector<std::string>& output);

class MYTime{
public:
static time_t getNow(){
	time_t ret;
	time(&ret);
	return ret;
}

static std::string toString(const time_t& t,double zone=8,const char* disp="%Y%m%d_%R"){
	time_t tz = t + zone*3600;
	struct tm TM;
	gmtime_r(&tz,&TM);
	char buff[15];
	strftime(buff,15,disp,&TM);
	buff[14] = '\0';
	return (std::string)buff;
}

static time_t toTime(const std::string& s/*20140708_18:40*/,double zone=8){
	const char* s_c = s.c_str();
	char* pstr;
	long year,month,day,hour,min,sec;
	year = strtol(s_c,&pstr,10);
	month = (year/100)%100;
	day = (year%100);
	year = year/10000;
	hour = min = sec = 0;
	if(*pstr){
		hour = strtol(++pstr,&pstr,10);
		if(*pstr){
			min = strtol(++pstr,&pstr,10);
			if (*pstr){
				sec = strtol(++pstr,&pstr,10);
			}
		}
	}
	//printf("%d %d %d\n", hour,min,sec);

    int leap_year = (year-1969)/4;	//year-1-1968
    int i = (year-2001)/100;		//year-1-2000
    leap_year -= ((i/4)*3+i%4);
    int day_offset = 0;
    for (i=0;i<month-1;i++)
    	day_offset += mon_day[i];
    bool isLeap = ((year%4==0&&year%100!=0)||(year%400==0));
    if (isLeap && month>2)
    	day_offset += 1;
    day_offset += (day-1);
    day_offset += ((year-1970)*365 + leap_year);
    int hour_offset = hour - zone;
    time_t ret = day_offset*86400 + hour_offset*3600 + min*60 + sec;

    return ret;
}

};

//PrintInfo用法 COMMON::PrintInfo::PrintDbg("redis return : [%s]", val.c_str());
class PrintInfo {
public:
	static int PrintLog(const char* format, ...) {
		time_t t;
		time(&t);
		char buff[MAXLOGLEN];
		va_list args;
		va_start(args, format);
		vsnprintf(buff, MAXLOGLEN, format, args);
		va_end(args);
		fprintf(stderr, "[MIOJI-Observer][LOG][%s]%s\n", MYTime::toString(t,8,"%Y%m%d_%H:%M:%S").c_str(), buff);
		return 0;
	}

	static int PrintDbg(const char* format, ...) {
		time_t t;
		time(&t);
		char buff[MAXLOGLEN];
		va_list args;
		va_start(args, format);
		vsnprintf(buff, MAXLOGLEN, format, args);
		va_end(args);
		fprintf(stderr, "[MIOJI-Observer][DBG][%s]%s\n", MYTime::toString(t,8,"%Y%m%d_%H:%M:%S").c_str(), buff);
		return 0;
    }

	static int PrintErr(const char* format, ...) {
		time_t t;
		time(&t);
		char buff[MAXLOGLEN];
		va_list args;
		va_start(args, format);
		vsnprintf(buff, MAXLOGLEN, format, args);
		va_end(args);
		fprintf(stderr, "[MIOJI-Observer][ERR][%s]%s\n", MYTime::toString(t,8,"%Y%m%d_%H:%M:%S").c_str(), buff);
		//fprintf(stderr, "%s", buff);
		return 0;
    }

    static int PrintMYErr(const char* format, ...) {
		time_t t;
		time(&t);
		char buff[MAXLOGLEN];
		va_list args;
		va_start(args, format);
		vsnprintf(buff, MAXLOGLEN, format, args);
		va_end(args);
		fprintf(stderr, "%s", buff);
		return 0;
    }
};

int random(const int N);

};//namespace SOGOUCHAT

#endif //__COMMON_FUNC_H__


