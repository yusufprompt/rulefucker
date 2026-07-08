#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/utsname.h>
#include <fcntl.h>
#include <stdarg.h>
#include <unistd.h>

// Uname hook
static int (*original_uname)(struct utsname *buf) = NULL;

// File system hooks
static int (*original_open)(const char *pathname, int flags, ...) = NULL;
static int (*original_open64)(const char *pathname, int flags, ...) = NULL;
static int (*original_openat)(int dirfd, const char *pathname, int flags, ...) = NULL;
static FILE* (*original_fopen)(const char *pathname, const char *mode) = NULL;
static FILE* (*original_fopen64)(const char *pathname, const char *mode) = NULL;

// Yardımcı fonksiyonlar
const char* get_config_path() {
    const char* path = getenv("RULEFUCKER_CONFIG_PATH");
    return path ? path : "/tmp/rulefucker.conf";
}

const char* get_spoof_dir() {
    const char* dir = getenv("RULEFUCKER_SPOOF_DIR");
    return dir ? dir : "/tmp/rulefucker_spoof";
}

// Yapılandırma okuyucu
void load_config(const char* key, char* dest, size_t max_len, const char* default_val) {
    if (!original_fopen) original_fopen = dlsym(RTLD_NEXT, "fopen");
    
    FILE *fp = original_fopen(get_config_path(), "r");
    if (!fp) {
        strncpy(dest, default_val, max_len);
        return;
    }

    char line[256];
    int found = 0;
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = 0;
        char *eq = strchr(line, '=');
        if (eq) {
            *eq = '\0';
            char *k = line;
            char *v = eq + 1;
            
            if (strcmp(k, key) == 0) {
                strncpy(dest, v, max_len - 1);
                dest[max_len - 1] = '\0';
                found = 1;
                break;
            }
        }
    }
    fclose(fp);
    
    if (!found) {
        strncpy(dest, default_val, max_len);
    }
}

int uname(struct utsname *buf) {
    if (!original_uname) original_uname = dlsym(RTLD_NEXT, "uname");
    
    int ret = original_uname(buf);
    if (ret != 0) return ret;
    
    load_config("sysname", buf->sysname, sizeof(buf->sysname), buf->sysname);
    load_config("nodename", buf->nodename, sizeof(buf->nodename), buf->nodename);
    load_config("release", buf->release, sizeof(buf->release), buf->release);
    load_config("version", buf->version, sizeof(buf->version), buf->version);
    load_config("machine", buf->machine, sizeof(buf->machine), buf->machine);
    
    return 0;
}

void resolve_path(const char *orig_path, char *resolved_path, size_t max_len) {
    if (orig_path == NULL) {
        resolved_path[0] = '\0';
        return;
    }
    
    // Yalnızca mutlak yolları (absolute paths) spoofluyoruz
    if (orig_path[0] == '/') {
        snprintf(resolved_path, max_len, "%s%s", get_spoof_dir(), orig_path);
        // Bu dosya gerçekten var mı kontrol et (gerçek access fonksiyonu ile)
        int (*real_access)(const char *, int) = dlsym(RTLD_NEXT, "access");
        if (real_access(resolved_path, F_OK) != 0) {
            // Yoksa orijinal yolu kullan
            strncpy(resolved_path, orig_path, max_len - 1);
            resolved_path[max_len - 1] = '\0';
        }
    } else {
        strncpy(resolved_path, orig_path, max_len - 1);
        resolved_path[max_len - 1] = '\0';
    }
}

int open(const char *pathname, int flags, ...) {
    if (!original_open) original_open = dlsym(RTLD_NEXT, "open");
    
    char spoofed_path[4096];
    resolve_path(pathname, spoofed_path, sizeof(spoofed_path));
    
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        int mode = va_arg(args, int);
        va_end(args);
        return original_open(spoofed_path, flags, mode);
    }
    
    return original_open(spoofed_path, flags);
}

int open64(const char *pathname, int flags, ...) {
    if (!original_open64) original_open64 = dlsym(RTLD_NEXT, "open64");
    
    char spoofed_path[4096];
    resolve_path(pathname, spoofed_path, sizeof(spoofed_path));
    
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        int mode = va_arg(args, int);
        va_end(args);
        return original_open64(spoofed_path, flags, mode);
    }
    
    return original_open64(spoofed_path, flags);
}

int openat(int dirfd, const char *pathname, int flags, ...) {
    if (!original_openat) original_openat = dlsym(RTLD_NEXT, "openat");
    
    char spoofed_path[4096];
    // openat için mutlak yolsa resolve et (bağıl yollar dirfd'ye bağlıdır, karmaşıktır)
    if (pathname && pathname[0] == '/') {
        resolve_path(pathname, spoofed_path, sizeof(spoofed_path));
    } else {
        strncpy(spoofed_path, pathname ? pathname : "", sizeof(spoofed_path) - 1);
    }
    
    if (flags & O_CREAT) {
        va_list args;
        va_start(args, flags);
        int mode = va_arg(args, int);
        va_end(args);
        return original_openat(dirfd, spoofed_path, flags, mode);
    }
    
    return original_openat(dirfd, spoofed_path, flags);
}

FILE *fopen(const char *pathname, const char *mode) {
    if (!original_fopen) original_fopen = dlsym(RTLD_NEXT, "fopen");
    
    char spoofed_path[4096];
    resolve_path(pathname, spoofed_path, sizeof(spoofed_path));
    
    return original_fopen(spoofed_path, mode);
}

FILE *fopen64(const char *pathname, const char *mode) {
    if (!original_fopen64) original_fopen64 = dlsym(RTLD_NEXT, "fopen64");
    
    char spoofed_path[4096];
    resolve_path(pathname, spoofed_path, sizeof(spoofed_path));
    
    return original_fopen64(spoofed_path, mode);
}
