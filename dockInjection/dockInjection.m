#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/objc-runtime.h>
#include "frida-gum.h"

#define VERBOSE

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

#define dockSwipeGesturePhase 123
#define dockSwipeGestureMotion 134
#define dockSwipeEvent 30
#define kIOHIDGestureMotionVerticalY 2
#define kIOHIDGestureMotionDoubleTap 6

// Undocumented CoreGraphics function:
CGPoint CGSCurrentInputPointerPosition(void);

static IMP originalMissionControlSetupSpacesStripControllerForDisplay;
static IMP originalChangeMode;
static IMP originalHandleEvent;
static int mouseOverrideCount = 0;

static void swizzle_missionControlSetupSpacesStripControllerForDisplay(id self, SEL _cmd, void *arg2, bool arg3)
{
    void (*originalFunction)(id, SEL, void *, bool) = (void (*)(id, SEL, void *, bool))originalMissionControlSetupSpacesStripControllerForDisplay;
    originalFunction(self, _cmd, arg2, true);
}

static CGPoint moveToTopOfScreen(CGPoint p)
{
    CGDirectDisplayID displayContainingCursor;
    uint32_t matchingDisplayCount = 0;
                                     
    CGGetDisplaysWithPoint(p, 1, &displayContainingCursor, &matchingDisplayCount);
    
    if (matchingDisplayCount >= 1) {
        CGRect rect = CGDisplayBounds(displayContainingCursor);
        p.y = rect.origin.y+1;
        return p;
        
    } else {
        NSLog(@"forceFullDesktopBar error: could not determine which screen contains mouse coordinates (%f %f)", p.x, p.y);
        return p;
    }
}

static void swizzle_changeMode(id self, SEL _cmd, long long mode)
{
    if (mode == 1) {
#ifdef VERBOSE
        NSLog(@"forceFullDesktopBar: Caught dock changing mode, will override pointer position");
#endif
        mouseOverrideCount = 1;
    }
    
    void (*originalFunction)(id, SEL, long long) = (void (*)(id, SEL, long long))originalChangeMode;
    originalFunction(self, _cmd, mode);
}

static bool isStartOfTrackpadSwipeUpEvent(CGEventType type, CGGesturePhase phase, uint64_t direction)
{
    return type == dockSwipeEvent && phase == kCGGesturePhaseBegan && direction == kIOHIDGestureMotionVerticalY;
}

static bool isDoubleTapEvent(CGEventType type, CGGesturePhase phase, uint64_t direction)
{
    return type == dockSwipeEvent && phase == kCGGesturePhaseNone && direction == kIOHIDGestureMotionDoubleTap;
}

static void checkDockEvent(CGEventRef event)
{
    if (!event) {
        return;
    }
    
    CGEventType type = CGEventGetType(event);
    CGGesturePhase phase = (CGGesturePhase)CGEventGetIntegerValueField(event, dockSwipeGestureMotion);
    uint64_t direction = (CGGesturePhase)CGEventGetIntegerValueField(event, dockSwipeGesturePhase);
    
    if (isStartOfTrackpadSwipeUpEvent(type, phase, direction)) {
#ifdef VERBOSE
        NSLog(@"forceFullDesktopBar: Caught beginning of vertical swipe, will override pointer position");
#endif
        mouseOverrideCount = 2;

    } else if (isDoubleTapEvent(type, phase, direction)) {
#ifdef VERBOSE
        NSLog(@"forceFullDesktopBar: Caught magic mouse double tap, will override pointer position");
#endif
        mouseOverrideCount = 2;
    }
}

static void swizzle_handleEvent(id self, SEL _cmd, CGEventRef event)
{
    checkDockEvent(event);
    void (*originalFunction)(id, SEL, CGEventRef) = (void (*)(id, SEL, CGEventRef))originalHandleEvent;
    originalFunction(self, _cmd, event);
}

static void swizzle_handleEventWithType(id self, SEL _cmd, CGEventRef event, CGEventType type)
{
    checkDockEvent(event);
    void (*originalFunction)(id, SEL, CGEventRef, CGEventType) = (void (*)(id, SEL, CGEventRef, CGEventType))originalHandleEvent;
    originalFunction(self, _cmd, event, type);
}

static CGPoint overrideCGSCurrentInputPointerPosition(void)
{
    CGPoint result = CGSCurrentInputPointerPosition();
    
    if (mouseOverrideCount > 0) {
        mouseOverrideCount -= 1;
        result = moveToTopOfScreen(result);
#ifdef VERBOSE
        NSLog(@"forceFullDesktopBar: overriding pointer position to: %f %f", result.x, result.y);
#endif
    }
    
    return result;
}

bool swizzleMethod(NSString *className, SEL orig, IMP newMethod, IMP *originalFunction)
{
    id targetClass = NSClassFromString(className);
    
    if (!targetClass) {
        NSLog(@"forceFullDesktopBar error: Unable to find %@ class", className);
        return false;
    }
    
    Method origMethod = class_getInstanceMethod(targetClass, orig);
    
    if (!origMethod) {
        NSLog(@"forceFullDesktopBar error: Unable to find target method in %@ class", className);
        return false;
    }
    
    (*originalFunction) = method_getImplementation(origMethod);
    method_setImplementation(origMethod, newMethod);
    
    NSLog(@"forceFullDesktopBar: Successfully swizzled target method in %@ class", className);
    return true;
}

void macOS10_11Method(void)
{
    swizzleMethod(@"WVExpose",
                  @selector(_missionControlSetupSpacesStripControllerForDisplay:showFullBar:),
                  (IMP)swizzle_missionControlSetupSpacesStripControllerForDisplay,
                  &originalMissionControlSetupSpacesStripControllerForDisplay);
}

bool swizzleWVExposeMethod(void)
{
    bool success = swizzleMethod(@"_TtC4Dock8WVExpose", @selector(changeMode:), (IMP)swizzle_changeMode,
                                 &originalChangeMode);
    if (success) {
        return true;
    }
    
    NSLog(@"forceFullDesktopBar: _TtC4Dock8WVExpose class not found, trying another...");
    
    success = swizzleMethod(@"WVExpose", @selector(changeMode:), (IMP)swizzle_changeMode, &originalChangeMode);
    
    if (success) {
        return true;
    }
    
    NSLog(@"forceFullDesktopBar: unable to swizzle WVExpose method, cannot proceed.");
    
    return false;
}

bool swizzleDOCKGesturesMethod(void)
{
    bool success = swizzleMethod(@"DOCKGestures", @selector(handleEvent:), (IMP)swizzle_handleEvent,
                                 &originalHandleEvent);
    
    if (success) {
        return true;
    }
    
    NSLog(@"forceFullDesktopBar: unable to swizzle [DOCKGestures handleEvent:], trying another");
    
    success = swizzleMethod(@"DOCKGestures", @selector(handleEvent:type:), (IMP)swizzle_handleEventWithType,
                            &originalHandleEvent);
    
    if (success) {
        return true;
    }
    
    NSLog(@"forceFullDesktopBar: unable to swizzle DOCKGestures method, cannot proceed.");
    return false;
}

void macOS10_13AndLaterMethod(void)
{
    if (!swizzleWVExposeMethod()) {
        return;
    }
    
    if (!swizzleDOCKGesturesMethod()) {
        return;
    }
    
    NSLog(@"forceFullDesktopBar: starting interception");
    GumInterceptor * interceptor;
    
    gum_init_embedded();
    interceptor = gum_interceptor_obtain();
    
    if (!interceptor) {
        NSLog(@"forceFullDesktopBar error: gum_interceptor_obtain failed ... cannot proceed");
        return;
    }
    
    gum_interceptor_begin_transaction(interceptor);
    
    GError *error = nil;
    GumModule *module = gum_module_load("/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock", &error);
    
    if (!module || error) {
        NSLog(@"forceFullDesktopBar error: gum_module_load failed ... cannot proceed");
        
        if (error && error->message) {
            NSLog(@"forceFullDesktopBar error message: %s", error->message);
        }
        
        return;
    }
     
    GumAddress funcAddr = gum_module_find_export_by_name (module, "CGSCurrentInputPointerPosition");
    
    if (!funcAddr) {
        NSLog(@"forceFullDesktopBar error: gum_module_find_export_by_name failed ... cannot proceed");
        return;
    }
    
    GumReplaceReturn result = gum_interceptor_replace(interceptor, (gpointer) funcAddr, overrideCGSCurrentInputPointerPosition, NULL, NULL);
    
    if (result != GUM_REPLACE_OK) {
        NSLog(@"forceFullDesktopBar error: gum_interceptor_replace failed with result: %d ... cannot proceed", result);
        return;
    }
    
    gum_interceptor_end_transaction (interceptor);
    
    NSLog(@"forceFullDesktopBar: successfully rebound CGSCurrentInputPointerPosition symbol");
}

__attribute__((constructor)) static void install(void) 
{
    NSLog(@"forceFullDesktopBar: dockInjection installed and running");
    
    NSInteger osxMajorVersion = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
    NSInteger osxMinorVersion = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    
    @autoreleasepool {
        if (osxMajorVersion == 10 && osxMinorVersion == 11) {
            NSLog(@"forceFullDesktopBar: Using 10.11 method...");
            macOS10_11Method();
        } else if (osxMajorVersion >= 11 || osxMinorVersion >= 13) {
            NSLog(@"forceFullDesktopBar: Using 10.13 and later method...");
            macOS10_13AndLaterMethod();
        } else {
            NSLog(@"forceFullDesktopBar error: macOS %ld.%ld is not supported", osxMajorVersion, osxMinorVersion);
        }
    }
}

#pragma clang diagnostic pop
