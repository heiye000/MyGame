#include "sockLinker.h"

using namespace std;

//非阻塞recv
/*int SockLinker::trecv(int fd, void *buff, size_t n, timeval *timeout) {
	int RecvSize = 0;
	fd_set wset;
	while(n-RecvSize > 0) {
		FD_ZERO(&wset);
		FD_SET(fd, &wset);
		int ret = select(fd+1, NULL, &wset, NULL, timeout);
		if(ret <= 0) {
			return -1;
		}
		ret = write(fd, buff, left);
		if(ret == 0) {
			return RecvSize;
		}
		buff = ((char *)buff)+ret;
		RecvSize += ret;
	}
	return RecvSize;
}

//非阻塞read
int SockLinker::tread(int fd, void *buff, size_t n, timeval *timeout) {
	fd_set rset;
	FD_ZERO(&rset);
	FD_SET(fd, &rset);
	int ret = select(fd+1, &rset, NULL, NULL, timeout);
	if(ret <= 0) {
		return -1;
	}
	ret = read(fd, buff, n);
	if(ret <= 0) {
		return ret;
	}
	((char *)buff)[ret] = '\0';
	return ret;
}*/

int SockLinker::generateHttpHeader(std::string& res, int len) {
	char buf[HTTP_HEADER_MAX_LENGTH];

	//generate header
	int ret = snprintf(buf, HTTP_HEADER_MAX_LENGTH, "HTTP/1.1 %d %s\r\n", 200, "OK");
	res = buf;

	// 生成响应报文时间戳
	time_t t;
	struct tm tmp_time;
	time(&t);
	char timestr[64];
	strftime(timestr, sizeof(timestr), "%a, %e %b %Y %H:%M:%S %Z", gmtime_r(&t, &tmp_time));
	ret = snprintf(buf,HTTP_HEADER_MAX_LENGTH,"Date:%s\r\n",timestr);
	res += buf;

	//add content length
	ret = snprintf(buf,HTTP_HEADER_MAX_LENGTH,"Content-Length:%d\r\n",len);
	res += buf;

	//add content type
	//ret = snprintf(buf,HTTP_HEADER_MAX_LENGTH,"Content-Type: %s; charset=%s\r\n","text/html","gbk");
	ret = snprintf(buf,HTTP_HEADER_MAX_LENGTH,"Content-Type: %s; charset=%s\r\n","text/html","utf-8");
	res += buf;

	//res += "Connection: Keep-Alive\r\n";
	snprintf(buf,HTTP_HEADER_MAX_LENGTH,"\r\n");
	res += buf;

	return res.length();
}

/*int writenTimeout(int fd, const void *buf, int buf_len, timeval *timeout) {
	int left = buf_len;
	int n;
	fd_set wset;
	while (left > 0) {
		FD_ZERO(&wset);
		FD_SET(fd, &wset);
		if(select(fd + 1, NULL, &wset, NULL, timeout) <= 0) {
			return -1;
		}
		if((n = write(fd, buf, left)) == 0) {
			return buf_len - left;
		}

		buf = (char *)buf + n;
		left -= n;
	}
	return buf_len;
}*/


char SockLinker::unhex(unsigned char c) {
	if (c < '@') {
		return c - '0';
	}
	return(c & 0x0f) + 9;
}

int SockLinker::URLDecode(const char *url, const int len, char *output, const int outlen) {
	const char *urlEnd = url+len;
	const char *outEnd = output+outlen-1;
	const char *outStart = output;
	while((url<urlEnd) && (output < outEnd)) {
		//以%开始的串转化为二进制
		if((url[0]=='%') && (url+2<=urlEnd) && isxdigit(url[1]) && isxdigit(url[2])) {
			*output = (unhex(url[1]) << 4) | unhex(url[2]);
			url += 3;
		}
		// 其它直接拷贝 
		else if(url[0] == '+') {
			*output = ' ';
			++url;
		}
		else {
			*output = *url;
			++url;
		}
		++output;
	}
	*output = 0;
	return output-outStart;
}

int SockLinker::URLEncode(const char *input, int len, char *output, int &outlen) {
	const unsigned char *c = (const unsigned char *)input;
	size_t p = 0;
	for (size_t j = 0; j < len; ++ j) {
		if(c[j] == ' ') {
			//output[p ++] = ' ';
			continue;
		}
		if (c[j] == '-' || c[j] == '.' || c[j] == '!' || c[j] == '~' || c[j] == '*' || c[j] == '\'' || c[j] == '(' || c[j] == ')' || (c[j] >= '0' && c[j] <= '9') || (c[j] >= 'a' && c[j] <= 'z') || (c[j] >= 'A' && c[j] <= 'Z')) {
			output[p ++] += c[j];
			continue;
		}
		char s[8] = {0};
		snprintf(s, 8, "%%%.2X", c[j]);
		s[7] = 0;
		for(int i = 0; s[i]; i ++) {
			output[p ++] = s[i];
		}
	}
	cout << "p = " << p << endl;
	output[p] = 0;
	cout << "output:" << output << endl;
	return 0;
}

int SockLinker::CheckMSG(const char buff[], int len, const char* &output, int &outlen) {
	int type = 0;
	output = buff;
	outlen = len;
	const char *pos = strstr(buff, "\r\n\r\n");
	if(pos != NULL) {
		//属于http请求
		const char *GetPos = strstr(buff, "GET");
		//是GET请求
		if(GetPos!=NULL && pos > GetPos) {
			const char *GetPosEnd = strstr(buff, " HTTP/");
			if(GetPosEnd!=NULL && GetPosEnd<pos) {
				output = GetPos+3;
				outlen = GetPosEnd - GetPos - 3;
				type = 1;
			}
		}
		const char *PostPos = strstr(buff, "POST");
		//是POST请求
		if(PostPos!=NULL && PostPos < pos) {
			const char *PostPosEnd = strstr(buff, " Transfer-Encoding: chunked");
			if(PostPosEnd == NULL) {
				output = PostPos+4;
				outlen = len - (PostPos - buff - 4);
				type = 2;
			}
		}
	}
	else {
		
	}
	return type;
}

int SockLinker::doWork() {
	int buffer_size = 2560;
	char recvBuff[buffer_size+1];
	int recvNum = 0;
	printf("doWork\n");
	while(1) {
		memset(recvBuff,'\0',buffer_size);
		recvNum = ::recv(sockfd, recvBuff, buffer_size, NULL);
		if(recvNum < 0) {
			if(errno == ECONNRESET || errno==ETIMEDOUT) {//ETIMEDOUT可能导致SIGPIPE 
				close(sockfd);
			}
			break;
		}
		else if(recvNum == 0) {
			close(sockfd);
			break;
		}

		recvBuff[recvNum]='\0';
		break;
	}

	cout << "recv = " << recvBuff << endl;

	const char *MSG;
	int MSGLen = 0;
	int type = CheckMSG(recvBuff, recvNum, MSG, MSGLen);

	cout << "LEN = " << MSGLen << endl;
	for(int i = 0; i < MSGLen; ++ i) {
		cout << *(MSG+i);
	}
	cout << endl;

	if(type == 1) {
		printf("GET\n");
		char URL[3000];
		int len;
		URLDecode(MSG, MSGLen, URL, len);
		cout << URL << endl;
	}
	else if(type == 2) {
		printf("POST\n");
	}
	else if(type == 0) {
		printf("OTHER\n");
	}
	//printf("message: %s \n", recvBuff); 
	return 0;
}
