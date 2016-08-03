#include "socketServer.h"

using namespace std;

SocketServer::SocketServer(const int thread_num, const int port):
MyThreadpool(thread_num, 0),m_port(port),BUF_EV_LEN(256),MAX_EPOLL_FD(8000),BACKLOG(50) {}

int SocketServer::open() {
	int epoll_fd = InitEpollFd();
	if(epoll_fd == -1) {
		perror("init epoll fd error.");
		printf("End at: %d",__LINE__);
		::exit(1);
	}

	struct epoll_event events[BUF_EV_LEN];
	struct epoll_event tempEvent;

	int sockConnect;
	struct sockaddr_in remoteAddr;
	int addrLen = sizeof(struct sockaddr_in);

	printf("Server Start!\n");
	while(1) {
		int nfds = epoll_wait(epoll_fd, events, BUF_EV_LEN, 1000);
		if(nfds > 5) {
			printf("connect num: %d/n", nfds);
		}
		if(nfds == -1) {
			printf("End at: %d",__LINE__);
			perror("epoll_wait error.");
			continue;
		}
		for(int i = 0; i < nfds; i ++) {
			//如果监听的端口出现变化,说明有新客户在连接
			if(m_listenfd == events[i].data.fd) {
				int sockConnect = accept(events[i].data.fd, (struct sockaddr*)&remoteAddr, (socklen_t*)&addrLen);
				if(sockConnect == -1) {
					printf("End at: %d",__LINE__);
					perror("accept error.");
					continue;
				}
				setnonblocking(sockConnect);
				tempEvent.events = EPOLLIN | EPOLLET;
				tempEvent.data.fd = sockConnect;
				//将新用户加入epoll监听队列
				if(epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sockConnect, &tempEvent) < 0) {
					printf("End at: %d",__LINE__);
					perror("epoll_ctl error.");
					return -1;
				}
			}
			else {
				//客户端出现变化
				//UseConnectFd(events[i].data.fd);
				//可以加入任务队列 让任务队列处理具体事物
				SockLinker *work = new SockLinker;
				work->sockfd = events[i].data.fd;
				//cout << "FILE" << endl;
				//m_taskqueue.put(work);
				push(work);
				//cout << "FILE IN" << endl;
			}
		}
	}
	return 0;
}

/*int SocketServer::UseConnectFd(int sockfd) {
	int buffer_size = 256;
	char recvBuff[buffer_size+1];
	int recvNum = 0;
	int buff_size = buffer_size*10;
	char *buff = (char*)calloc(1,buff_size);

	while(1) {
		//memset(recvBuff,'/0',buffer_size);
		recvNum = recv(sockfd, recvBuff, buffer_size, MSG_DONTWAIT);
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

		//数据超过预定大小，则重新分配内存
		if(recvNum+strlen(buff)>buff_size) {
			if((buff=(char *)realloc(buff,buff_size+strlen(buff)))==NULL) {
				break;
			}
		}
		recvBuff[recvNum]='\0';
		sprintf(buff,"%s%s",buff,recvBuff);
		if(recvNum<buffer_size) {
			break;
		}
	}

	if(recvBuff[0]=='0') {
		printf("%s\n",buff);
	};

	//if(strcmp(buff,policeRequestStr)==0) {
	//	sendMsg(sockfd, policyXML);
	//}
	//else if(strlen(buff)>0) {
	//	sendMsg(sockfd,buff);
	//}

	free(buff);
	//printf("message: %s /n", recvBuff); 
	return 0;
}*/

int SocketServer::InitEpollFd() {
	struct rlimit rt;
	rt.rlim_max = rt.rlim_cur = MAX_EPOLL_FD;
	if (setrlimit(RLIMIT_NOFILE, &rt) == -1) {
		//perror("setrlimit");
		printf("<br/> RLIMIT_NOFILE set FAILED: %s <br/>",strerror(errno));
		//::exit(1);
	}
	else {
		printf("设置系统资源参数成功！\n");
	}
	int s_epfd;
	struct epoll_event ev;
	m_listenfd = CreateTcpListenSocket();
	if(m_listenfd == -1) {
		perror("create tcp listen socket error");
		printf("End at: %d",__LINE__);
		return -1;
	}
	s_epfd = epoll_create(MAX_EPOLL_FD);
	ev.events = EPOLLIN;
	ev.data.fd = m_listenfd;
	if (epoll_ctl(s_epfd, EPOLL_CTL_ADD, m_listenfd, &ev) < 0) {
		perror("epoll ctl error");
		printf("End at: %d",__LINE__);
		return -1;
	}
	return s_epfd;
}
int SocketServer::CreateTcpListenSocket() {
	int sockfd;
	struct sockaddr_in localAddr;
	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		perror("create socket fail");
		printf("End at: %d",__LINE__);
		return -1;
	}
	setnonblocking(sockfd);
	bzero(&localAddr, sizeof(localAddr));
	localAddr.sin_family = AF_INET;
	localAddr.sin_port = htons(m_port);
	localAddr.sin_addr.s_addr = htonl(INADDR_ANY);

	unsigned int optval;
	optval = 0x1;
	setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &optval, 4);
	if(bind(sockfd,  (struct sockaddr*)&localAddr, sizeof(struct sockaddr)) == -1)	{
		perror("bind error");
		printf("End at: %d",__LINE__);
		return -1;
	}

	if(listen(sockfd, BACKLOG) == -1) {
		perror("listen error");
		printf("End at: %d",__LINE__);
		return -1;
	}
	return sockfd;
}

int SocketServer::setnonblocking(int sock) {
	int opts;
	opts=fcntl(sock,F_GETFL);
	if(opts<0) {
		perror("fcntl(sock,GETFL)");
		printf("End at: %d",__LINE__);
		::exit(1);
	}

	opts = opts|O_NONBLOCK;
	if(fcntl(sock,F_SETFL,opts) < 0) {	 
		perror("fcntl(sock,SETFL,opts)");
		printf("End at: %d",__LINE__);
		::exit(1);	
	}	
    return 0;
}
