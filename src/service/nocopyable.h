/****************************
Author:			屈天豪
Version:		v1.0
Descript:		禁止拷贝基类
date:			2016/7/24
tips:
	 私有继承此类以防止你的类被拷贝
*****************************/

#ifndef NOCOPYABLE_H_
#define NOCOPYABLE_H_

class Nocopyable
{
protected:
	Nocopyable(){}
	~Nocopyable(){}

private:
	Nocopyable(const Nocopyable&);
	void operator=(const Nocopyable&);
};


#endif