#ifndef __MEMPOOL_H__
#define __MEMPOOL_H__

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

//内存控制
class MemControl {
public:
	MemControl(const int &unitsize);
	~MemControl();
	void *ctlGet();					//得到数据
	void ctlDel(void *addr);		//交还数据
private:
	void ctlClear();		//释放
public:
	MemControl *pnext;	//下一个内存块地址
	void *mem;			//内存实体
	int pstart;		//下一个开始内存的地址
	const int size;		//总大小
	int remain;			//剩余大小
	const int m_unit;			//单元数据大小
};

//内存管理工具
class MemManage {
public:
	MemManage(const int &unitsize);
	void manageDel(void *paddr);
	void *manageGet();
	void manageClear();
private:
	void _malloc();	//分配m_pctl
	void _free();	//释放m_pctl
private:
	MemControl *m_pctl;		//内存控制
	MemControl *m_phead;	//第一个可用内存块地址
	int m_unit;
};

//内存池
class MemPool {
public:
	MemPool(const int &size);
	~MemPool();
public:
	void *get();				//得到内存
	void del(void *paddr);	//释放内存
	void clear();			//释放所有内存，清空内存池
private:
	int m_unit_size;		//单元大小
	int m_mem_size;			//总内存大小
	MemManage m_manage;		//内存管理器
};

#endif	//__MEMPOOL_H__
