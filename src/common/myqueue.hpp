#ifndef __MYQUEUE__
#define __MYQUEUE__

#include <iostream>


namespace COMMON {
//普通队列
template<typename T>
struct link_node {
	T _value;
	link_node *_next;
	link_node *_pre;
};

template<typename T>
class MyQueue {
public:
	MyQueue();
	void push(const T &v);
	T front();
	void pop();
	void clear();
	int size();
	bool isempty();
private:
	link_node<T> m_head;
	int m_size;
};

template<typename T>
MyQueue<T>::MyQueue() {
	m_head._next = &m_head;
	m_head._pre = &m_head;
	m_size = 0;
}

template<typename T>
void MyQueue<T>::push(const T &v) {
	link_node<T> *tmp = new link_node<T>();
	tmp->_value = v;

	tmp->_next = m_head._next;
	(m_head._next)->_pre = tmp;
	tmp->_pre = &m_head;
	m_head._next = tmp;

	m_size ++;
}

template<typename T>
void MyQueue<T>::pop() {
	link_node<T> *t = m_head._pre;

	t->_next->_next = &m_head;
	m_head._pre = t->_pre;

	m_size --;
	delete t;
}

template<typename T>
T MyQueue<T>::front() {
	return m_head._pre->_value;
}

template<typename T>
void MyQueue<T>::clear() {
	while(!isempty()) {
		pop();
	}
}

template<typename T>
int MyQueue<T>::size() {
	return m_size;
}

template<typename T>
bool MyQueue<T>::isempty() {
	return m_head._pre == &m_head;
}


}

#endif
