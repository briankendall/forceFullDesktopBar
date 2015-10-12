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
- (void)findProcessesAndInjectAfterDelay:(double)delay;
- (void)doPeriodicCheck:(NSTimer *)timer;
@end

@implementation Worker {
    NSSet *previousPids;
    uid_t targetUid;
    bool hasTargetUid;
}

- (id)initWithTargetUid:(uid_t)inTargetUid hasTargetUid:(bool)inHasTargetUid
{
    self = [super init];
    
    if (self) {
        previousPids = [NSSet set];
        targetUid = inTargetUid;
        hasTargetUid = inHasTargetUid;
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

// Finds new Dock processes since the last check (or since the process started) and
// injects our payload into any it finds.
- (void)findProcessesAndInjectAfterDelay:(double)delay
{
    NSSet *currentPids;
    
    if (hasTargetUid) {
        currentPids = getAllPIDsForProcessNameRunByUser("Dock", targetUid);
    } else {
        currentPids = getAllPIDsForProcessName("Dock");
    }
    
    NSMutableSet *newPids = [NSMutableSet setWithSet:currentPids];
    [newPids minusSet:previousPids];
    
    for(NSNumber *pidObj in newPids) {
        NSLog(@"Found Dock process... will inject into pid: %@", pidObj);
        
        if (delay > 0) {
            [self performSelector:@selector(injectIntoProcess:)
                       withObject:pidObj
                       afterDelay:delay];
        } else {
            [self injectIntoProcess:pidObj];
        }
    }
    
    previousPids = currentPids;
}

- (void)doPeriodicCheck:(NSTimer *)timer
{
    // Waiting a little bit after discovering the new process, just to make sure it's had ample time to
    // start up and get running before we mess with it.
    [self findProcessesAndInjectAfterDelay:1.0];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Worker *worker;
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        
        NSUInteger index = [arguments indexOfObject:@"-u"];
        
        if (index != NSNotFound && index+1 < [arguments count]) {
            worker = [[Worker alloc] initWithTargetUid:[arguments[index+1] intValue] hasTargetUid:true];
        } else {
            worker = [[Worker alloc] initWithTargetUid:0 hasTargetUid:false];
        }
        
        if ([arguments containsObject:@"-d"]) {
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:worker selector:@selector(doPeriodicCheck:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] run];
        } else {
            NSLog(@"Searching for Dock processes...");
            [worker findProcessesAndInjectAfterDelay:0];
        }
    }
    return 0;
}
