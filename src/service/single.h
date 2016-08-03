/****************************
Author:			屈天豪
Version:		v1.0
Descript:		单件模板
date:			2016/7/24
tips:
	1. 继承此单例模板以使用，使用此单件模板，不要在其中一个实例的析构函数中使用另一个单例实例
	2. 该单例模式无法运行在多线程下
*****************************/

#ifndef SINGLE_H_
#define SINGLE_H_
#include<stdexcept>

template<class T>
class CSingle
{
public:
	static T& getInstance(void);

protected:
	CSingle(void);
	virtual ~CSingle(void);
private:
	//禁止拷贝
	void operator=(const CSingle&);
	CSingle(const CSingle&);

	static void Create();
	static void OnDeadReference();


	static T* m_pInstance;
	static bool m_destroy;
};

template<class T>
T& CSingle<T>::getInstance( void )
{
	if (!m_pInstance)
	{
		if (m_destroy)
		{
			OnDeadReference();
		}
		else
		{
			Create();
		}
	}

	return *m_pInstance;
}



////////////////////////////////////////// init
template<class T>
T* CSingle<T>::m_pInstance = 0;

template<class T>
bool CSingle<T>::m_destroy = false;
//

template<class T>
CSingle<T>::~CSingle( void )
{
	m_pInstance = NULL;
	m_destroy = true;
}



template<class T>
CSingle<T>::CSingle( void )
{
}

template<class T>
void CSingle<T>::OnDeadReference()
{
	throw std::runtime_error("使用了死亡引用");
}

template<class T>
void CSingle<T>::Create()
{
	static T theInstance;
	m_pInstance = &theInstance;
}

#endif