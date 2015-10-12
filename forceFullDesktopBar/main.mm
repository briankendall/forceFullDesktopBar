//
//  main.m
//  forceFullDesktopBar
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "processes.h"
#include "injector.h"

@interface Worker : NSObject
- (void)checkForDock:(NSTimer *)timer;
@end

@implementation Worker {
    NSSet *previousPids;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        previousPids = [NSSet set];
    }
    
    return self;
}

- (void)injectIntoProcess:(NSNumber *)pidObj
{
    pid_t pid = pidObj.intValue;
    char path[4096];
    realpath("dockInjection.dylib", path);
    Injector inj;
    inj.inject(pid, path);
}

- (void)checkForDock:(NSTimer *)timer
{
    NSSet *currentPids = getAllPIDsForProcessName("Dock");
    
    NSMutableSet *newPids = [NSMutableSet setWithSet:currentPids];
    [newPids minusSet:previousPids];
    
    for(NSNumber *pidObj in newPids) {
        NSLog(@"Found Dock process... will inject into pid: %@", pidObj);
        // Waiting a little bit after discovering the new process, just to make sure it's had ample time to
        // start up and get running before we mess with it.
        [self performSelector:@selector(injectIntoProcess:)
                   withObject:pidObj
                   afterDelay:1.0];
    }
        
    previousPids = currentPids;
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Worker *worker = [[Worker alloc] init];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:worker selector:@selector(checkForDock:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
