#include "mycommonfuc.h"
#include <string>

namespace COMMON {
double *MathConstData::m_cos = NULL;
double *MathConstData::m_sin = NULL;
double *MathConstData::m_acos = NULL;
int MathConstData::m_accuracy = 0;
int MathConstData::m_size = 0;

int MathConstData::init(int accuracy) {
	if(MathConstData::m_cos == NULL || MathConstData::m_sin == NULL || MathConstData::m_acos == NULL) {
		MathConstData::m_cos = (double*)malloc(accuracy*sizeof(double));
		MathConstData::m_sin = (double*)malloc(accuracy*sizeof(double));
		MathConstData::m_acos = (double*)malloc(accuracy*sizeof(double));
		MathConstData::m_accuracy = accuracy;
		MathConstData::m_size = accuracy;
	}
	else if(MathConstData::m_size < accuracy) {
		MathConstData::m_cos = (double *)realloc((void*)MathConstData::m_cos, accuracy*sizeof(double));
		MathConstData::m_sin = (double *)realloc((void*)MathConstData::m_sin, accuracy*sizeof(double));
		MathConstData::m_acos = (double *)realloc((void*)MathConstData::m_acos, accuracy*sizeof(double));
		MathConstData::m_accuracy = accuracy;
		MathConstData::m_size = accuracy;
	}
	else {
		MathConstData::m_accuracy = accuracy;
	}
	for(int i = 0; i <= m_accuracy; i ++) {
		m_cos[i] = cos(i*PI/2/m_accuracy);
		m_sin[i] = sin(i*PI/2/m_accuracy);
		m_acos[i] = acos(i*2.0/m_accuracy - 1);
	}
	return 0;
}

std::string digital2char(const int &num) {
	if(num < 0) {
		return "少";
	}
	else if(num < 15) {
		return chinacharacter[num];
	}
	else {
		return "多";
	}
}

void sepString(std::string input, const std::string &sep, std::vector<std::string> &output) {
	output.clear();
	while(input.length()) {
		int pos = input.find(sep);
		if(pos >= 0) {
			output.push_back(input.substr(0, pos));
			input = input.substr(pos + sep.length());
			if(input.length() == 0) {
				output.push_back("");
			}
		}
		else {
			output.push_back(input);
			break;
		}
	}
}

int random(int Maxi) {
	if(Maxi > 1) {
		return rand() % Maxi;
	}
	return 0;
}
}

