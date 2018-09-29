//
//  dockInjection.m
//  dockInjection
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#import "dockInjection.h"

@import Foundation;
@import MachO;
@import ObjectiveC;

#import <mach/mach.h>
#import <sys/mman.h>

__attribute__((constructor)) void install() {
	unsigned char prologue[] = {
	    0x55,                   // push rbp
	    0x48, 0x89, 0xe5,       // mov  rbp,rsp
	    0x41, 0x57,             // push r15
	    0x41, 0x56,             // push r14
	    0x41, 0x55,             // push r13
	    0x41, 0x54,             // push r12
	    0x53,                   // push rbx
	    0x48, 0x83, 0xec, 0x78, // sub  rsp,0x78
	    0x4c, 0x89, 0xeb,       // mov  rbx,r13
	    0x4c, 0x89, 0x45, 0xb8, // mov  QWORD PTR [rbp-0x48],r8
	    0x48, 0x89, 0x4d, 0xb0, // mov  QWORD PTR [rbp-0x50],rcx
	    0x89, 0x55, 0xd0,       // mov  DWORD PTR [rbp-0x30],edx
	};

	unsigned char overwritten_code[] = {
	    0x8b, 0x4d, /*0xd0,*/ // mov ecx,dword ptr [rbp - /* 0x30 */] (makes it a bit more resilient to stack reshuffling)
	};

	unsigned char injected_code[] = {
	    0x48, 0x31, 0xc9, // xor rcx,rcx
	};

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
	void *prologue_address;
	if (!(prologue_address = memmem(dock_base_address, dock_size, prologue, sizeof(prologue)))) {
		NSLog(@"Could not find function prologue");
		return;
	}
	NSLog(@"Found function prologue at %p", prologue_address);

	void *injection_address;
	if (!(injection_address = memmem(prologue_address, dock_base_address + dock_size - prologue_address, overwritten_code, sizeof(overwritten_code)))) {
		NSLog(@"Could not find code to be overwritten");
		return;
	}
	uintptr_t injection_page_boundary = (uintptr_t)injection_address;
	injection_page_boundary &= ~(PAGE_SIZE - 1);
	if (mprotect((void *)injection_page_boundary, (uintptr_t)injection_address + sizeof(injected_code) - injection_page_boundary, PROT_READ | PROT_WRITE | PROT_EXEC)) {
		NSLog(@"Could not set memory protections due to error %d", errno);
		return;
	}
	NSLog(@"Set memory protections of page at %p to RWX", (void *)injection_page_boundary);
	memcpy(injection_address, injected_code, sizeof(injected_code));
	NSLog(@"Wrote %lu bytes of code at %p", sizeof(injected_code), injection_address);
}
