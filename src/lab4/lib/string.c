#include "string.h"
#include "stdint.h"

void *memset(void *dest, int c, uint64_t n) {
    char *s = (char *)dest;
    for (uint64_t i = 0; i < n; ++i) {
        s[i] = c;
    }
    return dest;
}

// 仿照memset函数实现
void *memcpy(void *dst, void *src, uint64_t n){
    char *d = (char *)dst;
    char *s = (char *)src;
    for(uint64_t i = 0; i < n; ++i){
        d[i] = s[i];
    }
    return dst;
}