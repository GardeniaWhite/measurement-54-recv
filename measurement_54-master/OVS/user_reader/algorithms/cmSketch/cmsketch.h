#ifndef _CM_SKETCH_H_
#define _CM_SKETCH_H_

#include "../BOBHash32.h"
//#include "../BOBHash32.cpp"
#include "../algorithms.h"
#include "/home/gxh/mycode/measurement_54-master/OVS/user_reader/tuple.h"

typedef struct
{
    unsigned long int diff_time;
    int counters;
    double avg;
} hashbucket;

class CMSketch : public Algorithm
{
    uint32_t *counters;
    int width;
    int d;
    BOBHash32 *hash;
    hashbucket *hb;

public:
    CMSketch(int tot_mem_in_bytes, int d);
    ~CMSketch();

    int insert(uint8_t *key, int keylen);
    int query(uint8_t *key, int keylen);

    // int insert_time(tuple_t *key, int keylen);
    // double query_avg(tuple_t *key, int keylen);
    void clear();
    void get_flowsize(vector<string> &flowIDs, unordered_map<string, int> &freq);
};

#endif //_CM_SKETCH_H_