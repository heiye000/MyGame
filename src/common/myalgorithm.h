#ifndef __MYALGORITHM__
#define __MYALGORITHM__

#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include "mymatrix.h"
#include <math.h>
#include "mycommonfuc.h"

namespace MYALG {

/*
k-平均算法
假设有 10 组数据，每个数据有 3 个特征，且这 10 组数据分为3个不同的类别：  这个为训练集
当判断一个新的数据属于哪个类别时：
1.求该数据与训练集数据的距离
2.选取前 K 个距离最小的训练集中的数据
3.在选取的 K 个训练集中的数据中，求出出现最多的类型
*/

template<typename T>
class K_avg {
public:
	K_avg(const int &type);
	//增加特征
	void add(const std::vector<T> &feature, const int &type);
	//判断属于第几类
	int judge(const std::vector<T> &feature);
private:
	//有几类数据
	int m_type;
	//每一类数据的特征
	std::vector<std::vector<T> > features;
};
/*
template<typename T>
K_avg::K_avg(const int &type):m_type(type) {
	features.resize(m_type);
}

template<typename T>
int K_avg::judge(const std::vector<T> &feature) {
	//for()
	return 0;
}

template<typename T>
void K_avg::add(const std::vector<T> &feature, const int &type) {
	features[type].push_back(feature);
}*/

/*
逻辑回归算法
思想:
用训练集去比配一组线性方程组
*/

template<typename T>
class LogisticReg {
public:
	LogisticReg(double alpha = 0.01, int maxIter = 100, std::string type = "gradDescent");
	//训练数据
	void fix(const std::vector<std::vector<double> > &train_x, const std::vector<double> &train_y);
	//预估数据
	bool predict(const std::vector<double> &train_x);
	//计算准确度
	double cal_precision(const std::vector<std::vector<double> > &train_x, const std::vector<double> &train_y);
	//显示权重
	void showweight() const;
	//读取分类器
	void load(const std::string &path);
	//保存分类器
	void dump(const std::string &path);
private:
	void fix_in(const MYMAT::MyMatrix<T> &train_x, const MYMAT::MyMatrix<T> &train_y);
	double sigmoid(const double &num);
	MYMAT::MyMatrix<T> sigmoid(const MYMAT::MyMatrix<T> &inmat);
	bool predict_in(const MYMAT::MyMatrix<T> &train_x);
	double cal_precision_in(const MYMAT::MyMatrix<T> &train_x, const MYMAT::MyMatrix<T> &train_y);
private:
	static const double E;
	double m_alpha;	//学习率
	int m_maxIter;	//最大迭代次数
	MYMAT::MyMatrix<T> m_weights;
	std::string m_type;
};

template<typename T>
double const LogisticReg<T>::E = 2.718281828459;

template<typename T>
LogisticReg<T>::LogisticReg(double alpha, int maxIter, std::string type):m_alpha(alpha), m_maxIter(maxIter), m_type(type)  {}

template<typename T>
void LogisticReg<T>::fix(const std::vector<std::vector<double> > &train_x, const std::vector<double> &train_y) {
	std::vector<std::vector<double> > train_x_t = train_x;
	for(int i = 0; i < train_x_t.size(); i ++) {
		train_x_t[i].insert(train_x_t[i].begin(), 1);
	}
	MYMAT::MyMatrix<T> train_X(train_x_t);
	MYMAT::MyMatrix<T> train_Y(train_y);
	fix_in(train_X, train_Y.transpose());
}

template<typename T>
bool LogisticReg<T>::predict(const std::vector<double> &train_x) {
	MYMAT::MyMatrix<T> train_X(train_x);
	return predict_in(train_X);
}

template<typename T>
double LogisticReg<T>::cal_precision(const std::vector<std::vector<double> > &train_x, const std::vector<double> &train_y) {
	std::vector<std::vector<double> > train_x_t = train_x;
	for(int i = 0; i < train_x_t.size(); i ++) {
		train_x_t[i].insert(train_x_t[i].begin(), 1);
	}
	MYMAT::MyMatrix<T> train_X(train_x_t);
	MYMAT::MyMatrix<T> train_Y(train_y);
	return cal_precision_in(train_X, train_Y);
}


template<typename T>
bool LogisticReg<T>::predict_in(const MYMAT::MyMatrix<T> &train_x) {
	MYMAT::MyMatrix<T> ret = sigmoid(train_x * m_weights);
	return ret.at(0, 0) > 0.5;
}

template<typename T>
void LogisticReg<T>::showweight() const {
	m_weights.show();
}

template<typename T>
double LogisticReg<T>::cal_precision_in(const MYMAT::MyMatrix<T> &train_x, const MYMAT::MyMatrix<T> &train_y) {
	int matchnum = 0;
	for(int i = 0; i < train_x.m_mat.size(); i ++) {
		//std::cout << "predict_in(train_x[i]) = " << predict_in(train_x[i]) << std::endl;
		if(predict_in(train_x[i]) == bool(train_y.at(0, i))) {
			matchnum ++;
		}
	}
	return double(matchnum) / train_x.m_mat.size();
}

template<typename T>
void LogisticReg<T>::fix_in(const MYMAT::MyMatrix<T> &train_x, const MYMAT::MyMatrix<T> &train_y) {
	m_weights.set(1, train_x.m_col, 1);
	//train_x.show();
	//train_y.show();
	//m_weights.show();
	//cout << m_alpha << endl;
	//批量梯度下降
	if(m_type == "gradDescent") {
		for(int iter = 0; iter < m_maxIter; iter ++) {
			//MYMAT::MyMatrix<T> train(train_x);
			//train_x * m_weights;
			auto out = sigmoid(train_x * m_weights);
			//std::cout << "out" << std::endl;
			//out.show();
			auto error = train_y - out;
			//std::cout << "error" << std::endl;
			//error.show();
			m_weights = m_weights + m_alpha * train_x.transpose() * error;
			//std::cout << "m_weights =" << std::endl;
			//m_weights.show();
			//std::cout << "i = " << iter << std::endl;
		}
	}
	//std::cout << "weight:" << std::endl;
	//m_weights.show();
	//随机下降
	else if (m_type == "stocGradDescent") {
	for(int iter = 0; iter < m_maxIter; iter ++) {
			for(int i = 0; i < train_x.m_mat.size(); i ++) {
				auto out = sigmoid(train_x[i] * m_weights);
				auto error = train_y[i] - out;
				//std::cout << "out" << std::endl;
				//out.show();
				//std::cout << "error" << std::endl;
				//error.show();
				//error.at(i, 0) -= out.at(0,0);
				//std::cout << "error_tmp" << std::endl;
				//error.show();
				m_weights = m_weights + m_alpha * train_x[i].transpose() * error;
				//std::cout << "weight" << std::endl;
				//m_weights.show();
			}
		}
	}
	else if(m_type == "smoothStocGradDescent") {
		//改进的随机梯度下降
		for(int iter = 0; iter < m_maxIter; iter ++) {
			int numSamples = train_x.m_mat.size();
			//auto train_x_t = train_x;
			//std::cout << "m_weights =" << std::endl;
			//m_weights.show();
			for(int i = 0; i < numSamples; i ++) {
				double alpha = 4.0 / (1.0 + iter + i) + 0.01;
				int irandon = COMMON::random(numSamples - i);
				auto out = sigmoid(train_x[irandon] * m_weights);
				//std::cout << "out" << std::endl;
				//out.show();
				auto error = train_y[irandon] - out;
				//std::cout << "error" << std::endl;
				//error.show();
				m_weights = m_weights + m_alpha * train_x[irandon].transpose() * error;
			}
		}
	}
}

template<typename T>
double LogisticReg<T>::sigmoid(const double &num) {
	//return 1.0 / (1 + exp(-num)
	double ret = 1.0 / (1 + pow(E, -num));
	return ret;
}

template<typename T>
MYMAT::MyMatrix<T> LogisticReg<T>::sigmoid(const MYMAT::MyMatrix<T> &inmat) {
	MYMAT::MyMatrix<T> newmat(inmat.m_row, inmat.m_col);
	for(int i = 0; i < inmat.m_row; i ++) {
		for(int j = 0; j < inmat.m_col; j ++) {
			newmat.m_mat[i][j] = sigmoid(inmat.m_mat[i][j]);
		}
	}
	return newmat;
}

template<typename T>
void LogisticReg<T>::load(const std::string &path) {
	std::ifstream fin;
}

template<typename T>
void LogisticReg<T>::dump(const std::string &path) {
	std::ofstream fout;
}









struct Point {
	double x, y;
	bool operator ==(const Point &rhs) {
		if(abs(x - rhs.x) < 0.00001 && abs(y - rhs.y) < 0.00001) {
			return true;
		}
		return false;
	}
};

struct Line {
	Point a, b;
};

class Cross_Line {
private:
	static double chacheng(Point a,Point b,Point c) {
		return (c.x - a.x)*(b.y - a.y) - (c.y - a.y)*(b.x - a.x);
	}
	static double max(double x, double y) {
		return x > y ? x : y;
	}
	static double min(double x, double y) {
		return x < y ? x : y;
	}
	public:
	static bool Cross(Line a, Line b)
	{
		if(a.a == b.a || a.a == b.b || a.b == b.a || a.b == b.b) {
			return 0;
		}
		if(max(a.a.x,a.b.x) < min(b.a.x,b.b.x) || min(a.a.x,a.b.x) > max(b.a.x,b.b.x)) {
			return 0;
		}
		if(max(a.a.y,a.b.y) < min(b.a.y,b.b.y) || min(a.a.y,a.b.y) > max(b.a.y,b.b.y)) {
			return 0;
		}
		if((chacheng(a.a,a.b,b.a) * chacheng(a.a,a.b,b.b) <= 0 && chacheng(b.a,b.b,a.a) * chacheng(b.a,b.b,a.b) <= 0)) {
			return 1;
		}
		return 0;
	}

	static int Cross(std::vector<Line> line)
	{
		int ans = 0;
		for(int i = 0; i < line.size(); i ++)
		{
			for(int j = i+1; j < line.size(); j ++)
			{
				if(Cross(line[i],line[j])) {
					ans ++;
				}
			}
		}
		return ans;
	}

};

}

#endif	//__MYALGORITHM__