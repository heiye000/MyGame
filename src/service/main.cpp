#include<iostream>
#define DEBUG
#define WIN32

//#include "ServerFrame.h"


using namespace std;

struct A
{
	A(int i_) :i(i_) {}
	~A(){ cout << "A::~A " << endl;}
	int i;
};

int main(char* argc, char* argv[])
{
	
	{
		using namespace qth;
		typedef SmartPtr<A, qth::DestructiveCopy>	DestroyPtr;

		DestroyPtr p(new A(3));
		cout << p->i << endl;
		p->i = 4;

		DestroyPtr p2 = p;
		cout << p2->i << endl;

		if (!p)
		{
			cout << "这个时候p已经是空的了" << endl;
		}
		
		if (p);
		if (p == p2);
		if (p > p2);
		if (p < p2);

	}


	

	getchar();
	return 0;
}