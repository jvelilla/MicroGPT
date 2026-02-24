#ifndef ET_MMAP_H
#define ET_MMAP_H

#include <stddef.h>

#ifdef _WIN32
#include <windows.h>

static inline void* et_mmap_file_ro(const char* filepath, size_t* out_size) {
    HANDLE hFile = CreateFileA(filepath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return NULL;
    
    LARGE_INTEGER size;
    if (!GetFileSizeEx(hFile, &size)) {
        CloseHandle(hFile);
        return NULL;
    }
    *out_size = (size_t)size.QuadPart;
    
    HANDLE hMap = CreateFileMappingA(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
    CloseHandle(hFile); // We can close the file handle after creating the mapping object
    
    if (hMap == NULL) return NULL;
    
    void* ptr = MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    CloseHandle(hMap); // We can close the mapping object after mapping the view
    
    return ptr;
}

static inline void et_munmap(void* ptr, size_t size) {
    if (ptr) {
        UnmapViewOfFile(ptr);
    }
}

#else
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

static inline void* et_mmap_file_ro(const char* filepath, size_t* out_size) {
    int fd = open(filepath, O_RDONLY);
    if (fd < 0) return NULL;
    
    struct stat st;
    if (fstat(fd, &st) < 0) {
        close(fd);
        return NULL;
    }
    *out_size = (size_t)st.st_size;
    
    void* ptr = mmap(NULL, *out_size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd); // File descriptor can be closed safely after mmap
    
    if (ptr == MAP_FAILED) return NULL;
    return ptr;
}

static inline void et_munmap(void* ptr, size_t size) {
    if (ptr && ptr != MAP_FAILED) {
        munmap(ptr, size);
    }
}

#endif
#endif
