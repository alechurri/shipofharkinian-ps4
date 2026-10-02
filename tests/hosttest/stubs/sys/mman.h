#pragma once
#include <stddef.h>
#include <sys/types.h>
#define PROT_READ 1
#define PROT_WRITE 2
#define MAP_PRIVATE 2
#define MAP_FIXED 0x10
#define MAP_ANON 0x1000
#define MAP_FAILED ((void*)-1)
