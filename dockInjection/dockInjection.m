//
//  dockInjection.m
//  dockInjection
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#import "dockInjection.h"

#import "mach_override.h"

@import Foundation;
@import MachO;
@import ObjectiveC;

#import <mach/mach.h>
#import <sys/mman.h>

__attribute__((constructor)) void install() {
	NSLog(@"forceFullDesktopBar installed and running");
	
	task_dyld_info_data_t dyld_info;
	mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
	kern_return_t error;
	if ((error = task_info(mach_task_self(), TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) != KERN_SUCCESS)) {
		NSLog(@"Could not get images loaded in Dock due to error %d", error);
		return;
	}
	struct dyld_all_image_infos *all_image_infos = (struct dyld_all_image_infos *)dyld_info.all_image_info_addr;
	void *dock_base_address = NULL;
	unsigned long long dock_size = 0;
	for (int i = 0; i < all_image_infos->infoArrayCount; ++i) {
		if (strstr(all_image_infos->infoArray[i].imageFilePath, "Dock.app/Contents/MacOS/Dock")) {
			NSLog(@"Found Dock base address at %p", dock_base_address = (void *)all_image_infos->infoArray[i].imageLoadAddress);
			dock_size = [NSFileManager.defaultManager attributesOfItemAtPath:[NSString stringWithUTF8String:all_image_infos->infoArray[i].imageFilePath] error:nil].fileSize;
			break;
		}
	}
	if (!dock_base_address) {
		NSLog(@"Could not find Dock base address");
		return;
	}
	
	void *function = NULL;
	for (int i = 0; i < sizeof(functions) / sizeof(*functions); ++i) {
		NSLog(@"Trying to find function for version %s...", functions[i].version);
		if ((function = memmem(dock_base_address, dock_size, functions[i].function, functions[i].length))) {
			NSLog(@"Found function at %p", function);
			break;
		}
	}
	
	if (!function) {
		NSLog(@"Could not find function");
	}
	
	NSLog(@"Overrode original function with status %d", mach_override_ptr(function, override, (void *)&original));
	
	NSLog(@"Original function is at %p", original);
	return;
}
