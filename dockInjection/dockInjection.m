//
//  dockInjection.m
//  dockInjection
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>

IMP originalMissionControlSetupSpacesStripControllerForDisplay;


void swizzle_missionControlSetupSpacesStripControllerForDisplay(id self, SEL _cmd, void *arg2, bool arg3)
{
    NSLog(@"Called swizzle_missionControlSetupSpacesStripControllerForDisplay!! arg2: %p, arg3: %d", arg2, arg3);
    
    void (*originalFunction)(id, SEL, void *, bool) = (void (*)(id, SEL, void *, bool))originalMissionControlSetupSpacesStripControllerForDisplay;
    originalFunction(self, _cmd, arg2, true);
}


void install(void) __attribute__ ((constructor));
void install()
{
    @autoreleasepool {
        NSLog(@"testlib: install");
        SEL orig;
        id targetClass;
        IMP newMethod;
        Method origMethod;
        
        targetClass = NSClassFromString(@"WVExpose");
        
        NSLog(@"targetClass: %p", targetClass);
        
        if (targetClass) {
            orig = @selector(_missionControlSetupSpacesStripControllerForDisplay:showFullBar:);
            newMethod = (IMP)swizzle_missionControlSetupSpacesStripControllerForDisplay;
            
            origMethod = class_getInstanceMethod(targetClass, orig);
            
            NSLog(@"origMethod: %p", origMethod);
            
            if (origMethod) {
                originalMissionControlSetupSpacesStripControllerForDisplay = method_getImplementation(origMethod);
                NSLog(@"originalMissionControlSetupSpacesStripControllerForDisplay: %p", originalMissionControlSetupSpacesStripControllerForDisplay);
                method_setImplementation(origMethod, newMethod);
            }
        }
    }
}
