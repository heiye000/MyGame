#include "CommonFuc.h"

namespace COMMON {
int random(const int N) {
	if(N > 1) {
		return rand()%N;
	}
	return 0;
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

};
