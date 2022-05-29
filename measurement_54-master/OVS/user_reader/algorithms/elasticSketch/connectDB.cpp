#include <iostream>
#include "hiredis/hiredis.h"

using namespace std;

int main()
{
    redisContext *pContext = redisConnect("127.0.0.1",6379);
    if(pContext->err)
    {
        redisFree(pContext);
        cout << "connect to redisServer fail" << endl;
        return -1;
    }
    cout << "connect to redisServer success" << endl;

    redisReply *pReply = (redisReply*)redisCommand(pContext, "AUTH a123456");
    cout << pReply->str << endl;

    pReply = (redisReply*)redisCommand(pContext,"set ISmileLi helloWorld");
    cout << pReply->str << endl;

    pReply = (redisReply*)redisCommand(pContext,"get ISmileLi");
    cout << pReply->str << endl;

    pReply = (redisReply*)redisCommand(pContext,"get key1");
    cout << pReply->str << endl;

    freeReplyObject(pReply);
    redisFree(pContext);
    return 0;
}

