#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <fcntl.h>	   /* open */
#include <unistd.h>	   /* exit */
#include <sys/ioctl.h> /* ioctl */
#include <sys/types.h>
#include <signal.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/mman.h>
#include <errno.h>
#include "hiredis/hiredis.h" // 连接数据库
#include "util.h"
#include "tuple.h"
#include "ringbuffer.h"
#include "./algorithms/cmSketch/cmsketch.h"
#include "./algorithms/elasticSketch/ElasticSketch.h"
#include "./algorithms/elasticSketch/ElasticSketch.cpp"

using namespace std;

// The number of ringbuffer
// **Must** be (# pmd threads + 1)
#define MAX_RINGBUFFER_NUM 2

// CMSketch
//int tot_mem_in_bytes = 600 * 1024;
//CMSketch *cm = new CMSketch(tot_mem_in_bytes, 3);
//CMSketch *cm1 = new CMSketch(tot_mem_in_bytes, 3);

// ESSketch
#define HEAVY_MEM (150 * 1024)
#define BUCKET_NUM (HEAVY_MEM / 64)
#define TOT_MEM_IN_BYTES (600 * 1024)
typedef ElasticSketch<BUCKET_NUM, TOT_MEM_IN_BYTES> Elastic;
Elastic *elastic = new Elastic();
// 用于操作数据库的指针
redisContext *pContext;

static inline char *ip2a(uint32_t ip, char *addr)
{
	sprintf(addr, "%.3d.%.3d.%.3d.%.3d", (ip & 0xff), ((ip >> 8) & 0xff), ((ip >> 16) & 0xff), ((ip >> 24) & 0xff));
	return addr;
}

void print_tuple(FILE *f, tuple_t *t)
{
	char ip1[30], ip2[30];

	fprintf(f, "%s(%u) <-> %s(%u) %u %d\n",
			ip2a(t->key.src_ip, ip1), ntohs(t->key.src_port),
			ip2a(t->key.dst_ip, ip2), ntohs(t->key.dst_port),
			t->key.proto, ntohs(t->size));
}

// 打印统计数据
void print_JSON(FILE *f, Elastic *elastic)
{
	char ip1[30];
	for (int i = 0; i < BUCKET_NUM; ++i)
		for (int j = 0; j < MAX_VALID_COUNTER; ++j)
		{
			uint32_t key = (*elastic).heavy_part.buckets[i].key[j];
			if (key != 0)
			{
				int val = (*elastic).query((uint8_t *)&key, 32);
				fprintf(f, "%s: %d\n", ip2a(key, ip1), val);
				// std::cout << key << std::endl;
			}
		}
}

// 将数据插入数据库
redisContext *connnectDB()
{
	redisContext *pContext = redisConnect("127.0.0.1", 6379);
	if (pContext->err)
	{
		redisFree(pContext);
		cout << "connect to redisServer fail" << endl;
		return nullptr;
	}
	cout << "connect to redisServer success" << endl;
	redisReply *pReply = (redisReply *)redisCommand(pContext, "AUTH a123456");
	cout << pReply->str << endl;
	// pReply = (redisReply*)redisCommand(pContext,"set ISmileLi helloWorld");
	// cout << pReply->str << endl;
	// pReply = (redisReply*)redisCommand(pContext,"get ISmileLi");
	// cout << pReply->str << endl;
	// pReply = (redisReply*)redisCommand(pContext,"get key1");
	// cout << pReply->str << endl;
	// freeReplyObject(pReply);
	// redisFree(pContext);
	return pContext;
}

void insertToDB(redisContext *pContext, Elastic *elastic)
{
	redisReply *pReply = nullptr;

	char ip[30];
	char setCommand[100];
	for (int i = 0; i < BUCKET_NUM; ++i)
	{
		for (int j = 0; j < MAX_VALID_COUNTER; ++j)
		{
			uint32_t key = (*elastic).heavy_part.buckets[i].key[j];
			if (key != 0)
			{
				int val = (*elastic).query((uint8_t *)&key, 32);
				sprintf(setCommand, "set %s %d\n", ip2a(key, ip), val);
				printf("%s", setCommand);
				pReply = (redisReply *)redisCommand(pContext, setCommand);
				cout << pReply->str << endl;
			}
		}
	}
	freeReplyObject(pReply);
}

long long int counter = 0;
bool KEEP_RUNNING;
void handler(int sig)
{
	if (sig == SIGINT)
	{
		KEEP_RUNNING = false;
		return;
	}
	// print_JSON(stdout, elastic);
	// insertToDB(pContext, elastic);
	printf("total insert: %lld\n", counter);
	counter = 0;
	//cm->clear();
	elastic->clear();
	alarm(1);
}

int main(int argc, char *argv[])
{
	// 连接数据库
	// pContext = connnectDB();

	tuple_t t;
	LOG_MSG("Initialize the ringbuffer.\n");

	/* link to shared memory (datapath) */
	ringbuffer_t *rbs[MAX_RINGBUFFER_NUM];
	for (int i = 0; i < MAX_RINGBUFFER_NUM; ++i)
	{
		char name[30] = {0};
		sprintf(name, "/rb_%d", i);
		printf("name=%s\n", name);
		rbs[i] = connect_ringbuffer_shm(name, sizeof(tuple_t));
		// printf("%p\n", rbs[i]);
	}
	printf("connected.\n");
	fflush(stdout);

	/* print number of pkts received per seconds */
	signal(SIGALRM, handler);
	signal(SIGINT, handler);
	alarm(1);

	/* create your measurement structure (sketch) here !!! */

	/* begin polling */
	int idx = 0;
	KEEP_RUNNING = true;
	int mycounter=0;
	while (KEEP_RUNNING)
	{
		if (t.flag == TUPLE_TERM)
		{
			break;
		}
		else
		{
			while (read_ringbuffer(rbs[(idx) % MAX_RINGBUFFER_NUM], &t) < 0 && KEEP_RUNNING)
			{
				idx = (idx + 1) % MAX_RINGBUFFER_NUM;
			}
			counter++;
			//printf("tuple_diff=%lx,mycounter=%d\n",t.diff_time,++mycounter);
			//  print_tuple(stdout, &t);
			//  Insert to sketch here
			// cm->insert_time(&t, 32);
			// cm1->insert_time(&t, 32);
			// elastic->insert((uint8_t*)&t, 32);
		}
	}
	printf("totally insert %d packets\n", counter);
	// redisFree(pContext);
	return 0;
}
