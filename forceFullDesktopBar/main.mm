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

#define kInjectionDylibFileName "dockInjection.dylib"
#define kBootstrapDylibFileName "bootstrap.dylib"

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

- (NSString *)getDylibPath:(NSString *)dylibFileName;
{
    NSString *localPath = [NSString pathWithComponents:@[[[NSFileManager defaultManager] currentDirectoryPath], dylibFileName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        return localPath;
    }
    
    NSString *usrLocalPath = [NSString pathWithComponents:@[@"/usr/local/forceFullDesktopBar", dylibFileName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:usrLocalPath]) {
        return usrLocalPath;
    }
    
    return nil;
}

- (NSString *)getInjectionDylibPath
{
    return [self getDylibPath:@(kInjectionDylibFileName)];
}

- (NSString *)getBootstrapDylibPath
{
    return [self getDylibPath:@(kBootstrapDylibFileName)];
}

- (void)injectIntoProcess:(NSNumber *)pidObj
{
    if (![self getInjectionDylibPath] || ![self getBootstrapDylibPath]) {
        NSLog(@"Error: cannot find necessary dylibs");
        return;
    }
    
    pid_t pid = pidObj.intValue;
    Injector inj([[self getBootstrapDylibPath] UTF8String]);
    inj.inject(pid, [[self getInjectionDylibPath] UTF8String]);
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

// Looks for necessary support files and reports any missing ones to the user
- (bool)checkForNecessaryFiles
{
    if (![self getInjectionDylibPath]) {
        fprintf(stderr, "Error: cannot find %s\n", kInjectionDylibFileName);
        fprintf(stderr, "This file must either be in the current directory or located in:\n/usr/local/forceFullDesktopBar/\n");
        return false;
    }
    
    if (![self getBootstrapDylibPath]) {
        fprintf(stderr, "Error: cannot find %s\n", kBootstrapDylibFileName);
        fprintf(stderr, "This file must either be in the current directory or located in:\n/usr/local/forceFullDesktopBar/\n");
        return false;
    }
    
    return true;
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
        
        if (![worker checkForNecessaryFiles]) {
            return 1;
        }
        
        if ([arguments containsObject:@"-d"]) {
            NSLog(@"Will continuously check for Dock processes...");
            [worker findProcessesAndInjectAfterDelay:0];
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:worker selector:@selector(doPeriodicCheck:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] run];
        } else {
            NSLog(@"Searching for Dock processes...");
            [worker findProcessesAndInjectAfterDelay:0];
        }
    }
    return 0;
}
