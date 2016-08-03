#include <iostream>
#include <fstream>
#include <stdlib.h>

#include "MyConfig.h"
#include "CommonFuc.h"

using namespace std;

std::tr1::unordered_map<std::string,std::string> MyConfig::_kv;

MyConfig::MyConfig(){}
MyConfig::~MyConfig(){}

bool MyConfig::init(const std::string& path) {
	ifstream fin;
	fin.open(path.c_str());
	if(!fin) {
		cerr << "can not open file " << path<<endl;
		return false;
	}
	string line = "";
	while(!fin.eof()) {
		getline(fin,line);
		cerr << line << endl;
		if(line.length() == 0 || line[0] == '#') {
			continue;
		}
		int pos = line.find("=");
		if(pos == std::string::npos) {
			cerr << "[WARNING]:format err->" << line << endl;
			continue;
		}
		string key = line.substr(0,pos);
		string val = line.substr(pos+1);
		_kv[key] = val;
	}
	return true;
	
}

std::string MyConfig::getString(const std::string& key){
	std::tr1::unordered_map<std::string,std::string>::const_iterator it;
	it = _kv.find(key);
	if(it != _kv.end()) {
		return it->second;
	}
	else {
		cerr << "MyConfig::Key(" << key << ") not exist" << endl;
		exit(0);
		return "";
	}
}

int MyConfig::getInt(const std::string& key) {
	return COMMON::convert<string,int>(getString(key));
}

double MyConfig::getDouble(const std::string& key) {
	return COMMON::convert<string,double>(getString(key));
}


