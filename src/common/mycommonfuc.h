#ifndef __MYCOMMONFUC__
#define __MYCOMMONFUC__

#include <string>
#include <iomanip>
#include <sstream>
#include <vector>
#include <sys/time.h>
#include <stdarg.h>
#include <tr1/unordered_map>
#include <cmath>
#include <iostream>

#define PI 3.1415926

namespace COMMON {

class MathConstData {
public:
	static double *m_cos;	//cos数组
	static double *m_sin;	//sin数组
	static double *m_acos;	//acos数组
	//static std::tr1::unordered_map<int, double> m_cos;
	//static std::tr1::unordered_map<int, double> m_sin;
	//static std::tr1::unordered_map<int, double> m_acos;
	static int m_accuracy;	//分母
	static int m_size;		//内存大小
private:
	//弧度映射关系函数
	static int TransmitRad(const double &Rad) {
		return int(Rad/PI*2*m_accuracy);
	}
	static int TransmitACos(const double &x) {
		return int((x+1)/2*m_accuracy);
	}
public:
	static double Sin(double Rad) {
		//Rad 的范围在 0~PI/2之间
		int Cnt = Rad/PI;
		Rad = Rad-Cnt*PI;
		while(Rad < 0) {
			Rad += PI*2;
		}
		while(Rad > PI*2) {
			Rad -= PI*2;
		}
		bool flag = 0;
		if(Rad > PI) {
			Rad = PI*2 - Rad;
			flag = 1;
		}
		if(Rad > PI/2) {
			Rad = PI - Rad;
		}
		return flag?-m_sin[TransmitRad(Rad)]:m_sin[TransmitRad(Rad)];
	}

	static double Cos(double Rad) {
		//Rad 的范围在 0~PI/2之间
		int Cnt = Rad/PI;
		Rad = Rad-Cnt*PI;
		while(Rad < 0) {
			Rad += PI*2;
		}
		while(Rad > PI*2) {
			Rad -= PI*2;
		}
		if(Rad > PI) {
			Rad = PI*2 - Rad;
		}
		bool flag = 0;
		if(Rad > PI/2) {
			Rad = PI - Rad;
			flag = 1;
		}
		//std::cout << Rad << std::endl;
		//std::cout << "TransmitRad(Rad) = "<< TransmitRad(Rad) << std::endl;
		return flag?-(m_cos[TransmitRad(Rad)]):(m_cos[TransmitRad(Rad)]);
	}

	static double ACos(double x) {
		//x 的范围在 0~1之间
		if(x < -1 || x > 1) {
			return 0;
		}
		return m_acos[TransmitACos(x)];
	}
public:
	static int init(int accuracy);
};

//数字转中文
static const char* chinacharacter[] = {"零","一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五"};
std::string digital2char(const int &num);

//各种格式的转换
template<typename InT, typename OutT>
OutT convert(const InT &input) {
	std::stringstream ss;
	ss << input;
	OutT ret;
	ss >> ret;
	return ret;
}

//将vector转换成数组
template<typename T>
std::string vector2array(const std::vector<T> &vinput) {
	std::string ret;
	ret += "[";
	for(int i = 0; i < vinput.size(); i ++) {
		if(i != 0) {
			ret += ", ";
		}
		ret += convert<T, std::string>(vinput[i]);
	}
	ret += "]";
	return ret;
}


/*
template<>
std::string vector2array(const std::vector<double> &vinput) {
	std::string ret;
	ret += "[";
	for(int i = 0; i < vinput.size(); i ++) {
		if(i != 0) {
			ret += ", ";
		}
		std::stringstream ss;
		ss << std::fixed << std::setprecision(2) << vinput[i];
		std::string tmp;
		ss >> tmp;
		ret += tmp;
	}
	ret += "]";
	return ret;
}*/


static const int mon_day[13] = {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
class MYTime {
private:
	
public:
	//得到当前时间
	/*static time_t getNow() {
		time_t ret;
		time(&ret);
		return ret;
	}
	//得到小时
	static int getHour(const time_t &t, const int zone = 8) {
		return (t/3600 + zone)%24;
	}*/
/*
struct tm {
int tm_sec;  //秒–取值区间为[0,59]
int tm_min;  //分 - 取值区间为[0,59]
int tm_hour; //时 - 取值区间为[0,23]
int tm_mday; //一个月中的日期 - 取值区间为[1,31]
int tm_mon;  //月份（从一月开始，0代表一月） - 取值区间为[0,11]
int tm_year; //年份，其值从1900开始
int tm_wday; //星期–取值区间为[0,6]，其中0代表星期天，1代表星期一，以此类推
}

可以通过 gmtime localtime gmtime_r loacltime_r 来将time_t转换成 tm
gmtime() 返回tm
localtime() 返回当地时间
gmtime_r() 存入指定的tm
loacltime_r() 返回当地时间

strftime()
*/
	//数字时间转换成 20110715_00:00格式
	static std::string toString(const time_t &t, int zone = 8, const char *disp="%Y%m%d_%R") {
		time_t tz = t + zone*8;
		struct tm TM;
		gmtime_r(&tz, &TM);
		char buff[15];
		strftime(buff, 15, disp, &TM);
		buff[14] = '\0';
		return std::string(buff);
	}
/*
int strtol(char *str, char **pstr, base);
str 为转换的字符串
pstr 为中指的地方 当pstr为空的时候 表名已经解析完str了
base 进制数 2~36
从第一个数字或者+-号开始开始 到最后一个非数字结束截取数字大小返回
*/
	//20110715_00:00时间转换成 数字
	static time_t toTime(const std::string &s, int zone = 8) {
		const char *s_c = s.c_str();
		char *pstr;
		long year, month, day, hour, min, sec;

		year = strtol(s_c, &pstr, 10);
		month = (year/100) % 100;
		day = year % 100;
		year /= 10000;
		hour = min = sec = 0;
		if(*pstr) {
			hour = strtol(++pstr, &pstr, 10);
			if(*pstr) {
				min = strtol(++pstr, &pstr, 10);
				if(*pstr) {
					sec = strtol(++pstr, &pstr, 10);
				}
			}
		}
		//计算闰年
		int leap_year = (year-1969)/4;
		int i = (year - 2001)/100;
		leap_year -= (i/4)*3 + i%4;
		
		int day_offset = 0;
		for(i = 0; i < month; i ++) {
			day_offset += mon_day[i];
		}
		if(((year%4 == 0 && year%100!=0) || (year%400 == 0)) && month > 2) {
			day_offset += 1;
		}
		day_offset += day-1;
		day_offset += (year-1970)*365 + leap_year;
		int hour_offset = hour - zone;
		time_t ret = day_offset*86400 + hour_offset*3600 + min*60 + sec;

		return ret;
	}

};

class MYTimer {
private:
/*
struct timeval {
	time_t tv_sec;	//seconds
	suseconds_t tv_usec; 	microseconds
};
*/
	struct timeval _b;
	struct timeval _e;
public:
	MYTimer() {
		gettimeofday(&_b, nullptr);
	}
	void start() {
		gettimeofday(&_b, nullptr);
	}
	int cost() {
		gettimeofday(&_e, nullptr);
		return (_e.tv_sec - _b.tv_sec)*1000000 + (_e.tv_usec - _b.tv_usec);
	}
};

class MyLog {
private:
	enum {MAXLOGLEN = 100};
public:
/*
函数参数是以数据结构:栈的形式存取,从右至左入栈。栈底高地址，栈顶低地址。
下面是 <stdarg.h> 里面重要的几个宏定义如下：
typedef char* va_list;	va_list 是一个字符指针，可以理解为指向当前参数的一个指针，取参必须通过这个指针进行
void va_start(va_list ap, prev_param);	对 ap 进行初始化，让它指向可变参数表里面的第一个参数
type va_arg(va_list ap, type);	返回这个指定类型的值，并且把 ap 的位置指向变参表的下一个变量位置
void va_end(va_list ap);	将这个 ap 指针关掉
*/
	static int printlog(const char *format, ...) {
		char buff[MAXLOGLEN];
		va_list args;
		va_start(args, format);
		vsnprintf(buff, MAXLOGLEN, format, args);
		va_end(args);
		fprintf(stderr, "log:%s\n", buff);
		return 0;
	}
};


//将字符串切割为数组
void sepString(std::string input, const std::string &sep, std::vector<std::string> &output);

//随机函数
int random(const int Maxi);
}

#endif
