#include "myMempool.h"

using namespace std;

void MemControl::ctlDel(void *addr) {
	*(int*)((char*)addr - sizeof(int)) = pstart;
	pstart = ((char*)addr - (char*)mem) - sizeof(int);
	remain ++;
}

void *MemControl::ctlGet() {
	assert(pstart != -1);
	void *p = ((char*)mem) + pstart + sizeof(int);
	pstart = *((int*)((char*)mem + pstart));
	remain --;
	return p;
}

MemControl::MemControl(const int &unitsize):pnext(NULL), mem(NULL), pstart(0), size(10000), remain(10000), m_unit(unitsize) {
	mem = malloc(size*m_unit);
	assert(mem != NULL);
	pstart = 0;
	for(int i = 0; i < size*m_unit; i += m_unit) {
		void *p = ((char *)mem + i);
		//printf("%lld\n", p);
		if(m_unit+i < size*m_unit) {
			*(int *)(p) = i+m_unit;
		}
		else {
			*(int *)(p) = -1;
		}
	}
	//cerr << "m_unit = " << m_unit << endl;
	for(int i = 0; i < size*m_unit; i += m_unit) {
		void *p = (char *)mem + i;
		//cout << *((int*)(p)) << endl;
	}
}

void MemControl::ctlClear() {
	free(mem);
	mem = NULL;
	pnext = NULL;
	pstart = 0;
}

MemControl::~MemControl() {
	ctlClear();
}


MemManage::MemManage(const int &unitsize):m_unit(unitsize), m_pctl(NULL), m_phead(NULL) {}

void MemManage::manageClear() {
	MemControl *np = m_pctl;
	while(np) {
		MemControl *p = np;
		np = np->pnext;
		delete p;
	}
}

void MemManage::manageDel(void *paddr) {
	MemControl *p = NULL;
	//cerr << "manageDel" << endl;
	for(p = m_pctl; p != NULL; p = p->pnext) {
		if((char*)paddr >= (char*)p->mem && (char*)paddr - (char*)p->mem < p->m_unit*p->size) {
			break;
		}
	}
	if(p != NULL) {
		//cerr << "Del" << endl;
		p->ctlDel(paddr);
	}
}

void *MemManage::manageGet() {
	MemControl *pm = m_phead;
	for(; pm != NULL; pm = pm->pnext) {
		if(pm->remain != 0) {
			break;
		}
	}
	if(pm == NULL) {
		pm = new(MemControl)(m_unit);
		assert(pm != NULL);
		pm->pnext = m_pctl;
		m_pctl = pm;
		m_phead = pm;
	}
	return pm->ctlGet();
}



MemPool::MemPool(const int &size):m_unit_size(size), m_mem_size(0), m_manage(size+sizeof(int)) {
	//初始化
}

MemPool::~MemPool() {
	//析构函数
	clear();
}

void *MemPool::get() {
	return m_manage.manageGet();
}

void MemPool::del(void *paddr) {
	m_manage.manageDel(paddr);
}

void MemPool::clear() {
	m_manage.manageClear();
	m_mem_size = 0;
}

