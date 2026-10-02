// Host test for soh/port/ps4/Ps4Heap.c with a fake kernel.
#define __PS4__ 1
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sys/mman.h>
#include <orbis/libkernel.h>
#define mmap ps4_mmap
#define munmap ps4_munmap
#include "../../Shipwright/soh/soh/port/ps4/Ps4Heap.c"
#undef mmap
#undef munmap

static int sFailBelow = 0; // direct memory allocations bigger than this fail
static int sKernelMmaps = 0, sKernelMunmaps = 0;
size_t sceKernelGetDirectMemorySize(void) { return 5ull << 30; }
int32_t sceKernelAllocateDirectMemory(off_t a, off_t b, size_t len, size_t align, int32_t t, off_t* out) {
    if (len > (1024ull << 20)) return -1; // pretend only 1 GiB is free: exercises the halving
    *out = 0x1000000; return 0;
}
int32_t sceKernelMapDirectMemory(void** addr, size_t len, int32_t prot, int32_t flags, off_t phys, size_t align) {
    uint8_t* p = (uint8_t*)_aligned_malloc(len, 0x200000);
    if (!p) return -1;
    memset(p, 0xAA, len); // dirty on purpose: the allocator must hand out zeroed pages anyway
    *addr = p; return 0;
}
int32_t sceKernelReleaseDirectMemory(off_t a, size_t b) { return 0; }
int32_t sceKernelMmap(void* a, size_t len, int32_t p, int32_t f, int32_t fd, off_t o, void** res) { sKernelMmaps++; *res = malloc(len); return 0; }
int32_t sceKernelMunmap(void* a, size_t len) { sKernelMunmaps++; return 0; }

static int sSystemFlexibleWorks = 0;
int32_t sceKernelReserveVirtualRange(void** addr, size_t len, int32_t flags, size_t align) { *addr = _aligned_malloc(len, 0x4000); return *addr ? 0 : -1; }
int32_t sceKernelMapNamedSystemFlexibleMemory(void** addr, size_t len, int32_t prot, int32_t flags, const char* name) { if (!sSystemFlexibleWorks) return -1; memset(*addr, 0x55, len); return 0; }
#define N 4096
int main(int argc, char** argv) {
    sSystemFlexibleWorks = argc > 1;
    static uint8_t* ptr[N]; static size_t len[N];
    size_t arena, inUse, peak; unsigned seed = 12345; long ops = 0;
    for (int round = 0; round < 200000; round++) {
        seed = seed * 1103515245u + 12345u; int i = (seed >> 8) % N;
        if (ptr[i]) {
            for (size_t k = 0; k < len[i]; k += 997) if (ptr[i][k] != (uint8_t)(i * 31 + k)) { printf("CORRUPTION slot %d\n", i); return 1; }
            if (ps4_munmap(ptr[i], len[i]) != 0) { printf("munmap failed\n"); return 1; }
            ptr[i] = NULL;
        } else {
            seed = seed * 1103515245u + 12345u;
            size_t l = ((seed >> 4) % 64 == 0) ? (size_t)(seed % (24u << 20)) + 1 : (size_t)(seed % (300u << 10)) + 1;
            uint8_t* p = (uint8_t*)ps4_mmap(NULL, l, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
            if (p == MAP_FAILED) { printf("mmap failed\n"); return 1; }
            if (((uintptr_t)p & 0x3FFF) != 0 && sKernelMmaps == 0) { printf("unaligned\n"); return 1; }
            for (size_t k = 0; k < l; k++) if (p[k] != 0) { printf("NOT ZEROED at %zu of %zu\n", k, l); return 1; }
            for (size_t k = 0; k < l; k += 997) p[k] = (uint8_t)(i * 31 + k);
            ptr[i] = p; len[i] = l;
        }
        ops++;
    }
    Ps4Heap_GetStats(&arena, &inUse, &peak);
    printf("kind %d: ops %ld, arena %zu MiB, in use %zu MiB, peak %zu MiB, kernel fallbacks %d\n", ops, arena >> 20, inUse >> 20, peak >> 20, sKernelMmaps);
    for (int i = 0; i < N; i++) if (ptr[i]) ps4_munmap(ptr[i], len[i]);
    Ps4Heap_GetStats(&arena, &inUse, &peak);
    printf("after freeing everything: in use %zu KiB (page map only)\n", inUse >> 10);
    // non-anonymous mappings must be forwarded
    void* f = ps4_mmap(NULL, 4096, PROT_READ, MAP_PRIVATE, 3, 0);
    printf("file mapping forwarded: %s\n", (sKernelMmaps > 0 && f != MAP_FAILED) ? "yes" : "NO");
    return 0;
}
