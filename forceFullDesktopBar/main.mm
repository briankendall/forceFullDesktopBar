//
//  main.m
//  forceFullDesktopBar
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "injector.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        char path[4096];
        realpath(argv[1], path);
        
        fprintf(stderr, "%s\n", path);
        
        Injector inj;
        pid_t pid;
        
        pid = inj.getProcessByName("Dock");
        if (!pid)
        {
            fprintf(stderr, "process %s not found\n", argv[1]);
            return 0;
        }
        
        fprintf(stderr, "pid: %u\n", pid);
        
        inj.inject(pid, path);
    }
    return 0;
}
