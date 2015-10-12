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
    void (*originalFunction)(id, SEL, void *, bool) = (void (*)(id, SEL, void *, bool))originalMissionControlSetupSpacesStripControllerForDisplay;
    originalFunction(self, _cmd, arg2, true);
}


void install(void) __attribute__ ((constructor));
void install()
{
    @autoreleasepool {
        SEL orig;
        id targetClass;
        IMP newMethod;
        Method origMethod;
        
        NSLog(@"dockInjection: installed and running");
        
        targetClass = NSClassFromString(@"WVExpose");
        
        if (!targetClass) {
            NSLog(@"Unable to find WVExpose class... cannot proceed");
            return;
        }
        
        orig = @selector(_missionControlSetupSpacesStripControllerForDisplay:showFullBar:);
        newMethod = (IMP)swizzle_missionControlSetupSpacesStripControllerForDisplay;
        origMethod = class_getInstanceMethod(targetClass, orig);
        
        if (!origMethod) {
            NSLog(@"Unable to find target method in WVExpose class... cannot proceed");
            return;
        }
        
        originalMissionControlSetupSpacesStripControllerForDisplay = method_getImplementation(origMethod);
        method_setImplementation(origMethod, newMethod);
        
        NSLog(@"Successfully swizzled target method in WVExpose class");
    }
}
