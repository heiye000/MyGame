/****************************
Author:			屈天豪
Version:		v1.0
Descript:		智能指针
date:			2016/7/21
*****************************/

#ifndef SMART_POINTERS_H_
#define SMART_POINTERS_H_
#include <iostream>
#include<algorithm>
#include<assert.h>
//#include "typeManip.h"
namespace qth
{
	// 选择类型， 二选一

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

	template<class T>
	class enable_shared_from_this;
	/*****************************
	默认存储策略
	功能：
	提供如何存取智能指针中所保存的原始指针的策略，提供智能指针对于 operator-> 和 operator* 的操作方式
	默认的存储策略只是提供简单的返回原始指针
	*****************************/
	template<class T>
	class DefaultSpStorage
	{
		template<class U> friend class enable_shared_from_this;
	public:
		typedef			T*		StoredType;
		typedef			T*		PointerType;		// operator-> return type
		typedef			T&		ReferenceType;		//operator*		return type;

		void Destroy() { delete pointee_; }
		StoredType Default() { return 0; } //让编译器帮你转型


		DefaultSpStorage(): pointee_(Default())				{}
		DefaultSpStorage(const StoredType& p): pointee_(p)	{}     
		void Swap(DefaultSpStorage& rhs)					{ std::swap(pointee_, rhs.pointee_); }


		template<class U>
		DefaultSpStorage(const DefaultSpStorage<U>&)		{}		

		//提领操作
		PointerType operator->() const						{ return pointee_; }
		ReferenceType operator*() const						{ return *pointee_; }

		//全局取原始指针/指针的引用/指针的常引用
		friend inline PointerType GetImpl(const DefaultSpStorage& sp)	{ return sp.pointee_; }
		friend inline StoredType& GetImplRef(DefaultSpStorage& sp)	{ return sp.pointee_; }
		friend inline const StoredType& GetImplRef(const DefaultSpStorage& sp)	{ return sp.pointee_; }

	private:
		StoredType pointee_;
	};

	/*****************************
	锁定式存储策略
	功能：
	每一次对于智能指针 operator->操作都会在其调用成员函数，或是改变成员变量的值期间将其锁定，操作完成后自动解锁，
	以便于运行在多线程环境中

	要求：
	对于智能指针 SmartPtr<class A>  classA必须提供 lock, 和 unlock  2两个方法
	禁止使用 operator*
	*****************************/
	template<class T>
	class LockedStorege
	{
	public:
		template<class U>
		struct Locker
		{
			U* lk_pointer;
			Locker(U* p): lk_pointer(p) { if(lk_pointer != 0) lk_pointer->lock();}
			~Locker()					{ if (lk_pointer != 0) lk_pointer->unlock();}

			U* operator->() {return lk_pointer;}
		};

		typedef		T*			StoredType;
		typedef		Locker<T>	PointerType;
		typedef		T&			ReferenceType;


		LockedStorege(): pointee_(Default()){}
		~LockedStorege(){}

		template<class U>
		LockedStorege(const LockedStorege<U>&): pointee_(Default()){}
		
		LockedStorege(const StoredType& p): pointee_(p){}

		PointerType operator->()
		{
			return Locker<T>(pointee_);
		}
		ReferenceType operator*();

		void Swap(LockedStorege& rhs)	{ std::swap(pointee_, rhs.pointee_);}
		void Destroy()					{delete pointee_;}
		StoredType Default() { return 0; } //让编译器帮你转型

		inline friend StoredType GetImpl(const LockedStorege& sp)	{ return sp.pointee_;}
		inline friend const StoredType& GetImplRef(const LockedStorege& sp)		{ return sp.pointee_;}
		inline friend StoredType& GetImplRef(LockedStorege& sp)			{ return sp.pointee_;} 
	private:
		StoredType pointee_;
	};

	/*****************************
	数组式存储策略
	功能：
	提供智能指针对于对象的数组管理

	要求：
	1. 智能指针提供功能的原则为尽量与原始指针保持一致， 因此对于数组的操作不提供获取数组元素数量的功能，
	用户必须在智能指针外手动保存数组的大小，就像原始指针一样（笑）

	2. 智能指针不提供类似于 int*p = new int[5];
	p[0]	=		1;
	p[1]	=		2;
	*(p + 3)=		4;
	这样的随机访问功能，此功能由转换策略提供，所以数组式存储策略应该与 AllowConversion 策略一同使用
	*****************************/
	template<class T>
	class ArrayStorage
	{

	public:
		typedef			T*				StoredType;
		typedef			T*				PointerType;
		typedef			T&				ReferenceType;

		ArrayStorage(): pointee_(Default())			{}
		ArrayStorage(StoredType p): pointee_(p)		{}

		template<class U>
		ArrayStorage(const ArrayStorage<U>&)		{}

		//提领操作
		PointerType operator->() const						{ return pointee_; }
		ReferenceType operator*() const						{ return *pointee_; }

		void Destroy()			{ delete[] pointee_; }
		void Swap(const ArrayStorage& rhs) { std::swap(rhs.pointee_, pointee_); }
		StoredType Default() { return 0; }

		friend inline StoredType GetImpl(const ArrayStorage& rhs)	{ return rhs.pointee_; }
		friend inline StoredType& GetImplRef(ArrayStorage& rhs)		{ return rhs.pointee_;}
		friend inline const StoredType& GetImplRef(const ArrayStorage& rhs) { return rhs.pointee_; }

	private:
		StoredType pointee_;
	};

	/*****************************
	引用计数所有权策略
	功能：
	掌管智能指针的拷贝和销毁的时机，引用计数策略为智能指针提供一个计数器，有多一个智能指针指向同一份数据则计数+1， 只有当所有
	指向同一份数据的智能指针生命周期结束才销毁这份数据
	*****************************/
	template<class T>
	class RefCounted
	{
	public:
		RefCounted(): pCount_(new unsigned int(1)) {}

		template<class U>
		RefCounted(const RefCounted<U>& rhs): pCount_(reinterpret_cast<const RefCounted&>(rhs).pCount_) {}

		//唯一验证
		friend inline bool isUnique(const RefCounted& rhs)
		{
			return (*rhs.pCount_ == 1) ? true : false; 
		}

		T Clone(const T& val)
		{
			++*pCount_;
			return val;
		}

		bool Delete(const T&)
		{
			if (!--*pCount_)
			{
				delete pCount_;
				pCount_ = NULL;
				return true;
			}
			return false;
		}

		void Swap(RefCounted& rhs)
		{
			std::swap(pCount_, rhs.pCount_);
		}

		

		//是否是摧毁式拷贝
		enum {destructiveCopy = false};

	private:
		unsigned int * pCount_;

	private:
		//以下这些函数专为 shared_from_this 服务， 其他不可调用
		template<class U> friend class enable_shared_from_this;

		friend inline const unsigned int* GetCount(const RefCounted& rhs)	{ return rhs.pCount_; }
		friend inline const unsigned int*& GetCountRef(const RefCounted& rhs)	{ return rhs.pCount_; }
		friend inline unsigned int*& GetCountRef(RefCounted& rhs)				{ return rhs.pCount_; }

		void ResetCount(const unsigned int* p)
		{
			if (pCount_)
			{
				delete pCount_;
				pCount_ = const_cast<unsigned int*>(p);
			}
		}

	};

	/*****************************
	侵入式引用计数所有权策略

	功能：
	将计数交由用户，相比于引用计数缩减了智能指针的大小
	备注:
	如果使用 锁定式存储策略在多线程环境下运行， 在引用计数和侵入式引用计数之间，请选择侵入式。
	要求：
	要求用户提供 addRef 和 ReelaseRef 两个接口
	void addRef();			增加引用计数
	int ReleaseRef();		减少引用计数，然后返回引用计数的值
	*****************************/
	template<class T>
	class COMRefCounted
	{
	public:
		COMRefCounted() {}

		template<class U>
		COMRefCounted(const COMRefCounted<U>&) {}
				
		static T Clone(const T& val)
		{
			if (val != 0)
				val->addRef();

			return val;
		}

		static bool Delete(const T& val)
		{
			if (val != 0)
				return val->ReleaseRef()==0 ? true : false;

			return false;
		}

		void Swap(const COMRefCounted&){}
		enum {destructiveCopy = false};
	};

	/*****************************
	摧毁式拷贝所有权策略
	功能：
	实现 std::auto_ptr 管理策略， 每一次的拷贝会将管理权限从拷贝源转移到目的智能指针中， 拷贝完成后，拷贝源 设置为NULL
	*****************************/
	template<class T>
	class DestructiveCopy
	{
	public:
		DestructiveCopy(){}

		template<class U>
		DestructiveCopy(const DestructiveCopy<U>&) {}

		template<class P>
		static T Clone(P& val)
		{
			T result(val);
			val = P();
			return result;
		}

		static bool Delete(const T&)		{ return true;}
		void Swap(DestructiveCopy&)	{}
		enum {destructiveCopy = true};
	};

	/*****************************
	深拷贝所有权策略
	功能：
	每次拷贝动作都会进行一次多态拷贝，每个智能指针指向的内存区块都是独立的
	要求：
	用户必须实作一个 Clone() 接口,实现多态拷贝
	*****************************/
	template<class T>
	class DeepCopy
	{
	public:
		DeepCopy() {}

		template<class U>
		DeepCopy(const DeepCopy<U>&) {}

		static T Clone(const T& val)
		{
			if (val != 0)
				return val->Clone();

			return T(0);
		}

		static bool Delete(const T&) { return true; }
		void Swap(DeepCopy&)	  {}
		enum {destructiveCopy = false};
	};

	/*****************************
	转换策略

	是否允许隐式自动转型
	AllowConversion		允许
	DisallowConversion	不允许
	*****************************/
	struct AllowConversion
	{
		enum {allow = true};
		void Swap(AllowConversion&)	{}
	};

	struct DisallowConversion
	{
		enum {allow = false};
		void Swap(DisallowConversion&)	{}
	};

	/*****************************
	检测策略  不检测
	*****************************/
	template<class T>
	struct NoCheck
	{
		NoCheck() {}

		template<class U>
		NoCheck(const NoCheck<U>&) {}

		static void OnDefault(const T&)		{}			//默认构造检测
		static void OnInit(const T&)		{}			//但参数构造检测
		static void OnDeference(const T&)	{}			//提领时检测
		void Swap(NoCheck&)					{}
	};

	/*****************************
	检测策略  断言检测
	*****************************/
	template<class T>
	struct AssertCheck
	{
		AssertCheck(){}

		template<class U>
		AssertCheck(const AssertCheck<U>&) {}

		static void OnDefault(const T&)	{}							//默认构造检测
		static void OnInit(T val)		{}			//但参数构造检测
		static void OnDeference(T val)	{ assert(val); }			//提领时检测
		void Swap(AssertCheck&)			{}
	};


	/*****************************
	智能指针
	功能：
	组合上述策略以运行，提供对普通指针的包装
	*****************************/
	template<class T,
		template<class>class OwnershipPolicy = RefCounted,		//所有权策略 目前提供深拷贝，引用计数，摧毁式拷贝和 侵入式策略
	class ConversionPolicy = DisallowConversion,			//是否支持自动转型   允许或不允许
		template<class> class CheckingPolicy = NoCheck,			//是否需要进行提领检测 不检测和断言检测
		template<class> class StoragePolicy = DefaultSpStorage> //存储策略， 目前提供 默认，锁定式，数组 三种策略
	class SmartPtr
		: public StoragePolicy<T>
		, public OwnershipPolicy<typename StoragePolicy<T>::StoredType>
		, public CheckingPolicy<typename StoragePolicy<T>::StoredType>
		, public ConversionPolicy
	{
		typedef			StoragePolicy<T>												SP;
		typedef			OwnershipPolicy<typename StoragePolicy<T>::StoredType>			OP;
		typedef			CheckingPolicy<typename StoragePolicy<T>::StoredType>			KP;
		typedef			ConversionPolicy												CP;

		typedef			typename SP::StoredType					StoredType;
		typedef			typename SP::PointerType				PointerType;
		typedef			typename SP::ReferenceType				ReferenceType;

		template<class U> friend class enable_shared_from_this;
public:
		//构造、析构
		SmartPtr()
		{
			KP::OnDefault(GetImpl(*this));
		}

		~SmartPtr()
		{
			if (OP::Delete(GetImpl(*this)))
			{
				SP::Destroy();
			}
		}
				
		explicit SmartPtr(const StoredType& p): SP(p)
		{
			KP::OnInit(GetImpl(*this));

			//根据管理的原始指针类型是否继承自 enable_shared_from_this 确定是否初始化弱引用
			//int i = SuperSubclass<char, T>::value;
			//(dynamic_cast<enable_shared_from_this<T>* >(p) != NULL) ? true : false;
			
			//is_init_shared_from_this(Int2Type<SuperSubclass<enable_shared_from_this<T>, T>::value>());			

		}
		
		//void is_init_shared_from_this(Int2Type<0>)
		//{
		//	//... 不是继承自 enable_shared_from_this 什么都不做
		//}

		//void is_init_shared_from_this(Int2Type<1>)
		//{
		//	//继承自  enable_shared_from_this  初始化弱引用
		//	GetImplRef(*this)->enable_shared_from_this_init(*this);
		//}
		
		//拷贝构造
		typedef typename Select<OP::destructiveCopy, SmartPtr&, const SmartPtr&>::Result	CopyArg;

		SmartPtr(CopyArg rhs): SP(rhs), OP(rhs), KP(rhs), CP(rhs)
		{
			GetImplRef(*this) = OP::Clone(GetImplRef(rhs));
		}

		//接受任意类型的智能指针作为参数的拷贝构造
		template<class T1,
			template<class> class OP1,
			class CP1,
			template<class> class KP1,
			template<class> class SP1>
		SmartPtr(const SmartPtr<T1 ,OP1, CP1, KP1, SP1>& rhs): SP(rhs), OP(rhs), CP(rhs), KP(rhs)
		{
			GetImplRef(*this) = OP::Clone(GetImplRef(rhs));
		}

		//接受任意类型智能指针为参数的拷贝构造函数（所有权策略为摧毁式拷贝[DestructiveCopy]）
		template<class T1,
			template<class> class OP1,
			class CP1,
			template<class> class KP1,
			template<class> class SP1>
		SmartPtr(SmartPtr<T1 ,OP1, CP1, KP1, SP1>& rhs): SP(rhs), OP(rhs), CP(rhs), KP(rhs)
		{
			GetImplRef(*this) = OP::Clone(GetImplRef(rhs));
		}

		//拷贝赋值
		SmartPtr& operator=(CopyArg& rhs)
		{
			SmartPtr temp(rhs);
			temp.Swap(*this);
			return *this;
		}

		template<class T1,
			template<class> class OP1,
			class CP1,
			template<class> class KP1,
			template<class> class SP1>
			SmartPtr& operator=(SmartPtr<T1, OP1, CP1, KP1, SP1>& rhs)
			{
				SmartPtr temp(rhs);
				temp.Swap(*this);
				return *this;
			}

			template<class T1,
				template<class> class OP1,
			class CP1,
				template<class> class KP1,
				template<class> class SP1>
			SmartPtr& operator=(const SmartPtr<T1,OP1, CP1, KP1, SP1>& rhs)
			{
				SmartPtr temp(rhs);
				temp.Swap(*this);
				return *this;
			}
			
		//提领
		const PointerType operator->() const
		{
			KP::OnDeference(GetImplRef(*this));
			return SP::operator->();
		}

		PointerType operator->()
		{
			KP::OnDeference(GetImplRef(*this));
			return SP::operator->();
		}

		const ReferenceType operator*()	const
		{
			KP::OnDeference(GetImplRef(*this));
			return SP::operator*();
		}

		ReferenceType operator*()
		{
			KP::OnDeference(GetImplRef(*this));
			return SP::operator*();
		}

		//重设智能指针的管理对象
		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		friend inline void Reset(SmartPtr<T1, OP1, CP1, KP1, SP1>& sp, typename SP1<T1>::StoredType& p);

		//相等性 与普通指针做比较 (备注： 自己实现operator<  而其他的操作符依赖与operator< 的实现，不过这种手法我忘记了，
		//需要回去翻翻书, 以后修改)
		bool operator!() const
		{
			return GetImpl(*this) == 0;
		}

		inline friend bool operator==(const SmartPtr& rhs, const PointerType p)
		{
			return GetImpl(rhs) == p;
		}

		inline friend bool operator==(const PointerType p, const SmartPtr& rhs)
		{
			return GetImpl(rhs) == p;
		}

		inline friend bool operator!=(const SmartPtr& rhs, const PointerType p)
		{
			return GetImpl(rhs) != p;
		}

		inline friend bool operator!=(const PointerType p, const SmartPtr& rhs)
		{
			return GetImpl(rhs) != p;
		}

		inline friend bool operator<(const SmartPtr& rhs, const PointerType p)
		{
			return GetImpl(rhs) < p;
		}

		inline friend bool operator<(const PointerType p, const SmartPtr& rhs)
		{
			return p < GetImpl(rhs);
		}

		inline friend bool operator>(const SmartPtr& rhs, const PointerType p)
		{
			return GetImpl(rhs) > p;
		}

		inline friend bool operator>(const PointerType p, const SmartPtr& rhs)
		{
			return p > GetImpl(rhs);
		}

		inline friend bool operator<=(const SmartPtr& rhs, const PointerType p)
		{
			return GetImpl(rhs) <= p;
		}

		inline friend bool operator<=(const PointerType p, const SmartPtr& rhs)
		{
			return p <= GetImpl(rhs);
		}

		inline friend bool operator>=(const SmartPtr& rhs, const PointerType p)
		{
			return GetImpl(rhs) >= p;
		}

		inline friend bool operator>=(const PointerType p, const SmartPtr& rhs)
		{
			return p >= GetImpl(rhs);
		}

		
		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		bool operator==(const SmartPtr<T1, OP1, CP1, KP1, SP1>&rhs) const
		{
			return GetImplRef(*this) == GetImplRef(rhs);
		}

		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		bool operator!=(const SmartPtr<T1, OP1, CP1, KP1, SP1>&rhs) const
		{
			return !operator==(rhs);
		}

		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		bool operator>(const SmartPtr<T1, OP1, CP1, KP1, SP1>&rhs) const
		{
			return GetImplRef(*this) > GetImplRef(rhs);
		}

		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		bool operator<(const SmartPtr<T1, OP1, CP1, KP1, SP1>&rhs) const
		{
			return GetImplRef(*this) < GetImplRef(rhs);
		}

		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		bool operator>=(const SmartPtr<T1, OP1, CP1, KP1, SP1>&rhs) const
		{
			return GetImplRef(*this) >= GetImplRef(rhs);
		}

		template<class T1,
			template<class> class OP1,
		class CP1,
			template<class> class KP1,
			template<class> class SP1>
		bool operator<=(const SmartPtr<T1, OP1, CP1, KP1, SP1>&rhs) const
		{
			return GetImplRef(*this) <= GetImplRef(rhs);
		}

	private:

		void Swap(SmartPtr& rhs)
		{
			OP::Swap(rhs);
			CP::Swap(rhs);
			KP::Swap(rhs);
			SP::Swap(rhs);
		}

		// if(sp) 处理
		struct Tester
		{
			Tester(int){}
			void dummy(){}
		};

		typedef void (Tester::*test_pfun)();
		typedef typename Select<CP::allow, Tester, test_pfun>::Result   pointer_conversion_type;

		//是否自动转换到 PointerType 类型
		struct Insipid
		{
			Insipid(PointerType){}
		};
		typedef typename Select<CP::allow, PointerType, Insipid>::Result AutoConversion;

	public:
		operator pointer_conversion_type() const
		{
			return !(*this) ? 0 : &Tester::dummy;
		}

		operator AutoConversion() const
		{
			return GetImpl(*this);
		}


	};

	//重设智能指针
	template<class T1,
		template<class> class OP1,
	class CP1,
		template<class> class KP1,
		template<class> class SP1>
	void Reset( SmartPtr<T1, OP1, CP1, KP1, SP1>& sp, typename SP1<T1>::StoredType& p )
	{
		SmartPtr<T1, OP1, CP1, KP1, SP1> tempSP(p);
		sp.Swap(tempSP);
	}

	/*************************************
	shared_from_this  只为 管理策略为引用计数服务的默认 SmartPtr 服务

	备注：
		1. 你不能在类的构造函数中 调用 shared_from_this
		2. 调用的对象，必须处于智能指针的管理下
	*************************************/
	template<class T>
	class enable_shared_from_this
	{
	protected:
		enable_shared_from_this(): m_p(0), m_pCount(0)
		{
		}

		virtual ~enable_shared_from_this(){}

		enable_shared_from_this(const enable_shared_from_this& rhs)
		{
			m_p = rhs.m_p;
			m_pCount = rhs.m_pCount;

		}

		enable_shared_from_this& operator=(const enable_shared_from_this& rhs)	
		{
			m_p = rhs.m_p;
			m_pCount = rhs.m_pCount;
			return *this;
		}

	public:
		SmartPtr<T> shared_from_this()
		{
			if (m_p && m_pCount)
			{
				SmartPtr<T> p;
				GetImplRef(p) = m_p;
				p.ResetCount(m_pCount);
				++(*m_pCount); 
				return p;
			}
			else
			{
				assert(false);        //违反备注的行为
				return SmartPtr<T>(); 
			}
		}

	public:
		//智能指针构造，
		void enable_shared_from_this_init(const SmartPtr<T>& sp)
		{
			m_p = GetImplRef(sp);
			m_pCount = const_cast<unsigned int*>(GetCount(sp));
		}


	private:
		typename SmartPtr<T>::StoredType  m_p;
		unsigned int* m_pCount;
	};


}

#endif