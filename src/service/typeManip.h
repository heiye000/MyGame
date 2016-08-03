/*
	类型可转换， 继承性判断
*/

#ifndef TYPEMANIP_H_
#define TYPEMANIP_H_

/**************************************************
int to type
***************************************************/
template<int v>
struct Int2Type
{
	enum {value = v};
};

/**************************************************
type to type
***************************************************/
template<class T>
struct Type2Type
{
	typedef T	OriginalType;
};

/**************************************************

***************************************************/
template<bool flag, class T, class U>
struct Select
{
	typedef T	Result;
};

template<class T, class U>
struct Select<false, T, U>
{
	typedef U	Result;
};

/**************************************************
是否是同一种类型
***************************************************/
template<class T, class U>
struct IsSampType
{
	enum {value = false};
};

template<class T>
struct IsSampType<T,T>
{
	enum {value = true};
};

/**************************************************
类型间可转换性的侦s测
***************************************************/
template<class T, class U>
struct ConversionHelper
{
	typedef	char	Small;				//代表小的类型
	struct	Big		{char du[2];};			//代表大的类型

	static	Big		Test(...);
	static	Small	Test(U);
	static	T		MakeT();
};


template<class T, class U>
struct Conversion
{
	typedef ConversionHelper<T,U> H;

	/*
	侦测T是否可转换为 U, 使用方式 Conversion<T, U>::exists,  true表示可转换， false 表示不可转换
	*/	
	enum {exists = sizeof(H::Small) == sizeof( H::Test(H::MakeT()) ) }; 

	/*
		侦测 T, U 是否可以互相转化
	*/
	enum {exists2Way = exists && Conversion<U, T>::exists };

	enum {sameType = 0};
};

template<class T>
struct Conversion<T,T>
{
	enum {exists = 1, exists2Way = 1, sameType = 1};
};

template<class T>
struct Conversion<T, void>
{
	enum {exists = 0, exists2Way = 0, sameType = 0};
};

template<class T>
struct Conversion<void, T>
{
	enum {exists = 0, exists2Way = 0, sameType = 0};
};

template <>
struct Conversion<void, void>    
{
	enum { exists = 1, exists2Way = 1, sameType = 1 };
};

/**************************************************
类型间继承性的侦测
***************************************************/
template<class T, class U>
struct SuperSubclass
{
	enum {value = Conversion<const volatile U*, const volatile T*>::exists &&
				  !Conversion<const volatile T*, const volatile void*>::sameType};
};

template<>
struct SuperSubclass<void, void>
{
	enum {value = false};
};

template<class T>
struct SuperSubclass<T, void>
{
	enum {value = false};
};

template<class U>
struct SuperSubclass<void, U>
{
	enum {value =  false};
};

#endif