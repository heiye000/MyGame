#ifndef __MYMATRIX__
#define __MYMATRIX__

#include <vector>
#include <iostream>

namespace MYMAT {

/*
模版类总结:
定义模板类的函数时必须加 template<typename T>

模版类的名称自动变为了 XX<T>
一旦使用模板，所有使用该class的地方都要声明一下模板


问题1:
模板类重载友元函数 只能实现Int的重载
问题2:
模版类友元函数重载元算符不能分离编译
*/

template<typename T>
class MyMatrix {
public:
	MyMatrix(const int &row, const int &col);
	MyMatrix(const MyMatrix &pmat);
	MyMatrix(const std::vector<std::vector<T> > &v_mat);
	MyMatrix(const std::vector<T> &v_mat);
	MyMatrix();

public:
	//显示函数
	void show() const;
	void show_size() const;

	//运算函数
	MyMatrix<T> transpose() const;
	void del(const int &id);
	void clear();
	void set(const T &value, const int &row = -1, const int &col = -1);
	void set(const std::vector<std::vector<T> > &v_mat);
	void set(const std::vector<T> &v_mat);

	MyMatrix<T> operator+ (const MyMatrix<T> &rhs) const;
	MyMatrix<T> operator- (const MyMatrix<T> &rhs) const;
	MyMatrix<T> operator* (const MyMatrix<T> &rhs) const;
	MyMatrix<T> operator= (const MyMatrix<T> &rhs);

	//取值函数
	const T & at(const int &x, const int &y) const;
	T & at(const int &x, const int &y);
	MyMatrix<T> operator[] (const int &id) const;

	friend MyMatrix<T> operator*(const double &lhs, const MyMatrix<T> &rhs) {
		MyMatrix<T> newmat(rhs.m_row, rhs.m_col);
		for(int i = 0; i < rhs.m_row; i ++) {
			for(int j = 0; j < rhs.m_col; j ++) {
				newmat.m_mat[i][j] = lhs * rhs.m_mat[i][j];
			}
		}
		return newmat;
	}
	//friend MyMatrix<T> operator+ (const MyMatrix<T> &lhs, const MyMatrix<T> &rhs);
	//friend MyMatrix operator -(const MyMatrix &lhs, const MyMatrix &rhs);
	//friend MyMatrix operator *(const MyMatrix &lhs, const MyMatrix &rhs);
public:
	std::vector<std::vector<T> > m_mat;
	int m_row;	//行
	int m_col;	//列

};

//构造函数
template<typename T>
MyMatrix<T>::MyMatrix(const int &row, const int &col):m_row(row), m_col(col) {
	set(0);
	/*for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		c.resize(m_col);
		m_mat.push_back(c);
		//std::cout << m_mat[i].size() << std::endl;
	}
	//std::cout << m_mat.size() << std::endl;
	*/
}

template<typename T>
MyMatrix<T>::MyMatrix(const MyMatrix<T> &pmat):m_row(pmat.m_row), m_col(pmat.m_col) {
	for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		for(int j = 0; j < m_col; j ++) {
			c.push_back(pmat.m_mat[i][j]);
		}
		m_mat.push_back(c);
	}
}

template<typename T>
MyMatrix<T>::MyMatrix(const std::vector<std::vector<T> > &v_mat) {
	m_row = v_mat.size();
	m_col = v_mat[0].size();
	for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		for(int j = 0; j < m_col; j ++) {
			c.push_back(v_mat[i][j]);
		}
		m_mat.push_back(c);
	}
}

template<typename T>
MyMatrix<T>::MyMatrix(const std::vector<T> &v_mat) {
	m_row = 1;
	m_col = v_mat.size();
	for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		for(int j = 0; j < m_col; j ++) {
			c.push_back(v_mat[j]);
		}
		m_mat.push_back(c);
	}
}

template<typename T>
MyMatrix<T>::MyMatrix() {}


template<typename T>
void MyMatrix<T>::show() const{
	for(int i = 0; i < m_row; i ++) {
		for(int j = 0; j < m_col; j ++) {
			std::cout << m_mat[i][j] << " ";
		}
		std::cout << std::endl;
	}
}

template<typename T>
void MyMatrix<T>::show_size() const{
	std::cout << "row = " << m_row << ", col = " << m_col << std::endl;
}




template<typename T>
MyMatrix<T> MyMatrix<T>::transpose() const{
	MyMatrix<T> newmat(m_col, m_row);
	for(int i = 0; i < m_row; i ++) {
		for(int j = 0; j < m_col; j ++) {
			newmat.m_mat[j][i] = m_mat[i][j];
		}
	}
	return newmat;
}

/*template<typename T>
void MyMatrix<T>::del(const int &id) {
	int i = 0;
	for(auto it = m_mat.begin(); it != m_mat.end(); it ++, i ++) {
		if(i == id) {
			m_mat.erase(it);
			break;
		}
	}
}*/

template<typename T>
void MyMatrix<T>::clear() {
	m_mat.clear();
}

template<typename T>
void MyMatrix<T>::set(const T &value, const int &row, const int &col) {
	clear();
	if(row != -1 && col != -1) {
		m_row = row;
		m_col = col;
	}
	for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		for(int j = 0; j < m_col; j ++) {
			c.push_back(value);
		}
		m_mat.push_back(c);
	}
}

template<typename T>
void MyMatrix<T>::set(const std::vector<std::vector<T> > &v_mat) {
	clear();
	m_row = v_mat.size();
	m_col = v_mat[0].size();
	for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		for(int j = 0; j < m_col; j ++) {
			c.push_back(v_mat[i][j]);
		}
		m_mat.push_back(c);
	}
}

template<typename T>
void MyMatrix<T>::set(const std::vector<T> &v_mat) {
	clear();
	m_row = 1;
	m_col = v_mat.size();
	for(int i = 0; i < m_row; i ++) {
		std::vector<T> c;
		for(int j = 0; j < m_col; j ++) {
			c.push_back(v_mat[i][j]);
		}
		m_mat.push_back(c);
	}
}


template<typename T>
MyMatrix<T> MyMatrix<T>::operator+ (const MyMatrix<T> &rhs) const {
	//矩阵不一样大的时候
	if(m_col != rhs.m_col || m_row != rhs.m_row) {
		MyMatrix<T> newmat(m_row, m_col);
		return newmat;
	}
	MyMatrix<T> newmat = *this;
	for(int i = 0; i < m_row; i ++) {
		for(int j = 0; j < m_col; j ++) {
			newmat.m_mat[i][j] += rhs.m_mat[i][j];
		}
	}
	return newmat;
}

template<typename T>
MyMatrix<T> MyMatrix<T>::operator -(const MyMatrix<T> &rhs) const {
	//矩阵不一样大的时候
	if(m_col != rhs.m_col || m_row != rhs.m_row) {
		MyMatrix<T> newmat(m_row, m_col);
		return newmat;
	}
	MyMatrix<T> newmat = *this;
	for(int i = 0; i < m_row; i ++) {
		for(int j = 0; j < m_col; j ++) {
			newmat.m_mat[i][j] -= rhs.m_mat[i][j];
		}
	}
	return newmat;
}

template<typename T>
MyMatrix<T> MyMatrix<T>::operator *(const MyMatrix<T> &rhs) const {
	//矩阵不能相乘的时候
	if(m_col != rhs.m_row) {
		MyMatrix<T> newmat((*this).m_col, rhs.m_row);
		return newmat;
	}
	//std::cout << "m_col = " << m_col << std::endl;
	//std::cout << "m_row = " << m_row << std::endl;
	//std::cout << "rhs.m_col = " << rhs.m_col << std::endl;
	MyMatrix<T> newmat(m_row, rhs.m_col);
	for(int i = 0; i < m_row; i ++) {
		for(int j = 0; j < rhs.m_col; j ++) {
			for(int k = 0; k < m_col; k ++) {
				newmat.m_mat[i][j] += (*this).m_mat[i][k] * rhs.m_mat[k][j];
			}
		}
	}
	return newmat;
}

template<typename T>
MyMatrix<T> MyMatrix<T>::operator= (const MyMatrix<T> &rhs) {
	m_row = rhs.m_row;
	m_col = rhs.m_col;
	m_mat = rhs.m_mat;
	return (*this);
}

template<typename T>
MyMatrix<T> MyMatrix<T>::operator[] (const int &id) const {
	//当id过大时
	if(id >= m_mat.size()) {
		MyMatrix<T> newmat(1, m_col);
		return newmat;
	}
	MyMatrix<T> newmat(m_mat[id]);
	//newmat.show();
	return newmat;
}

template<typename T>
T & MyMatrix<T>::at(const int &x, const int &y) {
	//当id过大时
	//newmat.show();
	//std::cout << "no const" << std::endl;
	return this->m_mat[x][y];
}

template<typename T>
const T & MyMatrix<T>::at(const int &x, const int &y) const {
	//当id过大时
	//newmat.show();
	return this->m_mat[x][y];
}

template<typename T>
void MyMatrix<T>::del(const int &id) {
	m_mat.erase(m_mat.begin() + id);
}
/*
template<typename T>
MyMatrix<T> operator+ (const MyMatrix<T> &lhs, const MyMatrix<T> &rhs) {
	MyMatrix<T> newmat = lhs;
	for(int i = 0; i < lhs.m_row; i ++) {
		for(int j = 0; j < lhs.m_col; j ++) {
			newmat.m_mat[i][j] += rhs.m_mat[i][j];
		}
	}
	return newmat;
	//return lhs;
}*/

/*
template<typename T>
MyMatrix MyMatrix<T>::operator -(const MyMatrix &lhs, const MyMatrix &rhs) {
	MyMatrix<T> newmat = lhs;
	for(int i = 0; i < lhs.m_row; i ++) {
		for(int j = 0; j < lhs.m_col; j ++) {
			newmat.m_mat[i][j] -= rhs.m_mat[i][j];
		}
	}
	return newmat;
}

template<typename T>
MyMatrix MyMatrix<T>::operator *(const MyMatrix &lhs, const MyMatrix &rhs) {
	MyMatrix<T> newmat(rhs.m_col, rhs.m_row);
	for(int i = 0; i < rhs.m_col; i ++) {
		for(int j = 0; j < rhs.m_row; j ++) {
			for(int k = 0; k < lhs.m_col; k ++) {
				newmat.m_mat[i][j] += lhs.m_mat[i][k] * rhs.m_mat[k][j];
			}
		}
	}
	return newmat;
}*/

}

#endif