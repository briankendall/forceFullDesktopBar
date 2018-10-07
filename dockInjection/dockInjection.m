#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/objc-runtime.h>
#import "fishhook.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

// Undocumented CoreGraphics function:
CGPoint CGSCurrentInputPointerPosition();

static IMP originalMissionControlSetupSpacesStripControllerForDisplay;
static IMP originalChangeMode;
static int mouseOverrideCount = 0;
static CGPoint (*originalCGSCurrentInputPointerPosition)();

static void swizzle_missionControlSetupSpacesStripControllerForDisplay(id self, SEL _cmd, void *arg2, bool arg3)
{
    void (*originalFunction)(id, SEL, void *, bool) = (void (*)(id, SEL, void *, bool))originalMissionControlSetupSpacesStripControllerForDisplay;
    originalFunction(self, _cmd, arg2, true);
}

static CGPoint moveToTopOfScreen(CGPoint p)
{
    NSArray *screens = [NSScreen screens];
    
    for(NSScreen *screen in screens) {
        CGRect rect = NSRectToCGRect([screen frame]);
        
        if (CGRectContainsPoint(rect, p)) {
            p.y = rect.origin.y+1;
            return p;
        }
    }
    
    NSLog(@"forceFullDesktopBar error: could not determine which screen contains mouse coordinates (%f %f)", p.x, p.y);
    
    return p;
}

void swizzle_changeMode(id self, SEL _cmd, long long mode)
{
    if (mode == 1) {
        mouseOverrideCount = 1;
    }
    
    void (*originalFunction)(id, SEL, long long) = (void (*)(id, SEL, long long))originalChangeMode;
    originalFunction(self, _cmd, mode);
}

static CGPoint overrideCGSCurrentInputPointerPosition()
{
    CGPoint result = originalCGSCurrentInputPointerPosition();
    
    if (mouseOverrideCount > 0) {
        mouseOverrideCount -= 1;
        return moveToTopOfScreen(result);
    } else {
        return result;
    }
}

void macOS10_11Method()
{
    id targetClass = NSClassFromString(@"WVExpose");
    
    if (!targetClass) {
        NSLog(@"forceFullDesktopBar error: Unable to find WVExpose class... cannot proceed");
        return;
    }
    
    SEL orig = @selector(_missionControlSetupSpacesStripControllerForDisplay:showFullBar:);
    IMP newMethod = (IMP)swizzle_missionControlSetupSpacesStripControllerForDisplay;
    Method origMethod = class_getInstanceMethod(targetClass, orig);
    
    if (!origMethod) {
        NSLog(@"forceFullDesktopBar error: Unable to find target method in WVExpose class... cannot proceed");
        return;
    }
    
    originalMissionControlSetupSpacesStripControllerForDisplay = method_getImplementation(origMethod);
    method_setImplementation(origMethod, newMethod);
    
    NSLog(@"forceFullDesktopBar: Successfully swizzled target method in WVExpose class");
}

void macOS10_13AndLaterMethod()
{    
    id targetClass = NSClassFromString(@"_TtC4Dock8WVExpose");
    
    if (!targetClass) {
        NSLog(@"forceFullDesktopBar error: Unable to find _TtC4Dock8WVExpose class... cannot proceed");
        return;
    }
    
    SEL orig = @selector(changeMode:);
    IMP newMethod = (IMP)swizzle_changeMode;
    Method origMethod = class_getInstanceMethod(targetClass, orig);
    
    if (!origMethod) {
        NSLog(@"forceFullDesktopBar error: Unable to find target method in _TtC4Dock8WVExpose class... cannot proceed");
        return;
    }
    
    originalChangeMode = method_getImplementation(origMethod);
    method_setImplementation(origMethod, newMethod);
    
    int result = rebind_symbols((struct rebinding[2]){{"CGSCurrentInputPointerPosition", overrideCGSCurrentInputPointerPosition, (void *)&originalCGSCurrentInputPointerPosition}}, 1);
    
    if (result != 0) {
        NSLog(@"forceFullDesktopBar error: rebind_symbols failed with result: %d ... cannot proceed", result);
        return;
    }
    
    NSLog(@"forceFullDesktopBar: Successfully swizzled target method in _TtC4Dock8WVExpose class and rebound CGSCurrentInputPointerPosition symbol");
}

__attribute__((constructor)) void install()
{
    NSLog(@"forceFullDesktopBar: dockInjection installed and running");
    
    NSInteger osxMinorVersion = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    
    @autoreleasepool {
        if (osxMinorVersion == 11) {
            NSLog(@"forceFullDesktopBar: Using 10.11 method...");
            macOS10_11Method();
        } else if (osxMinorVersion >= 13) {
            NSLog(@"forceFullDesktopBar: Using 10.13 and later method...");
            macOS10_13AndLaterMethod();
        } else {
            NSLog(@"forceFullDesktopBar error: macOS 10.%ld is not supported", osxMinorVersion);
        }
    }
}

#pragma clang diagnostic pop
