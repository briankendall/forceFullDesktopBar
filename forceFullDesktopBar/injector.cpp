#include "injector.h"

#include <cstdio>
#include <cstring>

#include <mach/mach.h>
#include <mach/thread_act.h>
#include <mach/mach_init.h>
#include <pthread.h>
#include <dlfcn.h>
#include <signal.h>
#include <sys/proc_info.h>
#include <libproc.h>
#include <syslog.h>
#include <stdarg.h>

void printError(const char *format, ...)
{
    va_list argList1, argList2;
    
    va_start(argList1, format);
    vsyslog(LOG_ERR, format, argList1);
    va_end(argList1);
    
    va_start(argList2, format);
    vprintf(format, argList2);
    va_end(argList2);
}

Injector::Injector(const char *bootstrapPath) : module(0), bootstrapfn(0)
{
    module = dlopen(bootstrapPath,
        RTLD_NOW | RTLD_LOCAL);

    printf("module: %p\n", module);
    if (!module)
    {
        printError("forceFullDesktopBar error: dlopen error: %s\n", dlerror());
        return;
    }

    bootstrapfn = dlsym(module, "bootstrap");
    printf("bootstrapfn: %p\n", bootstrapfn);

    if (!bootstrapfn)
    {
        printError("forceFullDesktopBar error: could not locate bootstrap fn\n");
        return;
    }
}

Injector::~Injector()
{
    if (module)
    {
        dlclose(module);
        module = NULL;
    }
}

void Injector::inject(pid_t pid, const char* lib)
{
    if (!module || !bootstrapfn)
    {
        printError("forceFullDesktopBar error: failed to inject: module:%p bootstrapfn:%p\n", module, bootstrapfn);
        return;
    }
    
    mach_error_t err = mach_inject((mach_inject_entry)bootstrapfn, lib, strlen(lib) + 1, pid, 0);
    
    if (err != 0) {
        printError("forceFullDesktopBar error: mach_inject failed with error code: %d\n", err);
    }
}

pid_t Injector::getProcessByName(const char *name)
{
    int procCnt = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[1024];
    memset(pids, 0, sizeof pids);
    proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));

    for (int i = 0; i < procCnt; i++)
    {
        if (!pids[i]) continue;
        char curPath[PROC_PIDPATHINFO_MAXSIZE];
        char curName[PROC_PIDPATHINFO_MAXSIZE];
        memset(curPath, 0, sizeof curPath);
        proc_pidpath(pids[i], curPath, sizeof curPath);
        size_t len = strlen(curPath);
        if (len)
        {
            size_t pos = len;
            while (pos && curPath[pos] != '/') --pos;
            strcpy(curName, curPath + pos + 1);
            if (!strcmp(curName, name))
            {
                return pids[i];
            }
        }
    }
    return 0;
}
