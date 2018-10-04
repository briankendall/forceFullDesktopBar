//
//  dockInjection.h
//  dockInjection
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#import <stdbool.h>

#define FUNCTION(...) (unsigned char[]){__VA_ARGS__}, \
	                  sizeof((unsigned char[]){__VA_ARGS__}) / sizeof(unsigned char)

static void (*original)(void *, void *, bool, void *, void *);

static void override(void *arg1, void *arg2, bool collapsed, void *arg4, void *arg5) {
	original(arg1, arg2, false, arg4, arg5);
}

static struct {
	char *version;
	unsigned char *function;
	int length;
} functions[] =
{
	{
		"10.14.1 Beta (18B50c)",
		FUNCTION(
			0x55,
			0x48, 0x89, 0xe5,
			0x41, 0x57,
			0x41, 0x56,
			0x41, 0x55,
			0x41, 0x54,
			0x53,
			0x48, 0x83, 0xec, 0x78,
			0x4c, 0x89, 0xeb,
			0x4c, 0x89, 0x45, 0xb8,
			0x48, 0x89, 0x4d, 0xb0,
			0x89, 0x55, 0xd0,
			0x49, 0x89, 0xf5,
			0x49, 0x89, 0xfc,
			0x4c, 0x89, 0x65, 0xa8,
			0x45, 0x31, 0xf6,
			0x44, 0x88, 0x73, 0x70,
			0x0f, 0x57, 0xc0,
			0x48, 0x8d, 0xbd, 0x60, 0xff, 0xff, 0xff,
			0x0f, 0x29, 0x47, 0x10,
			0x0f, 0x29, 0x07,
			0x48, 0x83, 0x67, 0x20, 0x00,
			0x41, 0xb7, 0x01,
			0x44, 0x88, 0x7f, 0x28,
			0x48, 0x8d, 0x73, 0x78,
			0xe8, 0xba, 0x89, 0x00, 0x00,
			0x48, 0x83, 0xa3, 0xb0, 0x00, 0x00, 0x00,
			0x00,
			0x48, 0x83, 0xa3, 0xa8, 0x00, 0x00, 0x00,
			0x00,
			0x44, 0x88, 0xbb, 0xb8, 0x00, 0x00, 0x00,
			0x48, 0x83, 0xa3, 0xc0, 0x00, 0x00, 0x00,
			0x00,
			0x44, 0x88, 0xb3, 0xc8, 0x00, 0x00, 0x00,
			0x48, 0x83, 0xa3, 0xd0, 0x00, 0x00, 0x00,
			0x00,
			0x44, 0x88, 0xb3, 0xd8, 0x00, 0x00, 0x00,
			0x48, 0x83, 0xa3, 0x10, 0x01, 0x00, 0x00,
			0x00,
			0x48, 0x83, 0xa3, 0x08, 0x01, 0x00, 0x00,
			0x00,
			0x48, 0x83, 0xa3, 0x00, 0x01, 0x00, 0x00,
			0x00,
			0x48, 0x83, 0xa3, 0xf8, 0x00, 0x00, 0x00,
			0x00,
			0x48, 0x83, 0xa3, 0xf0, 0x00, 0x00, 0x00,
			0x00,
			0x48, 0x83, 0xa3, 0xe8, 0x00, 0x00, 0x00,
			0x00,
			0x66, 0xc7, 0x83, 0x18, 0x01, 0x00, 0x00,
			0x01, 0x00,
			0x48, 0x8d, 0x7b, 0x10,
			0x6a, 0x0a,
			0x59,
			0x4c, 0x89, 0xe6,
			0xf3, 0x48, 0xa5,
			0x48, 0x8d, 0x05, 0x9d, 0x22, 0x22, 0x00,
			0x44, 0x8a, 0x38,
			0x41, 0x80, 0xf7, 0x01,
			0x31, 0xff,
			0xe8, 0x3a, 0x38, 0xed, 0xff,
			0x6a, 0x07,
			0x5a,
			0xbe, 0x1a, 0x02, 0x00, 0x00,
			0x48, 0x89, 0xc7,
			0xe8, 0xf2, 0xc6, 0x0f, 0x00,
			0x48, 0x89, 0x45, 0xa0,
			0x4c, 0x89, 0xe7,
			0xe8, 0x3e, 0x68, 0xee, 0xff,
			0x4c, 0x89, 0xe7,
			0xe8, 0x36, 0x68, 0xee, 0xff,
			0x4c, 0x89, 0xef,
			0xe8, 0x72, 0xc4, 0x0f, 0x00,
			0x4c, 0x8b, 0x65, 0xb0,
			0x4c, 0x89, 0xe7,
			0xe8, 0xb2, 0x01, 0xed, 0xff,
			0x4c, 0x8b, 0x75, 0xb8,
			0x4c, 0x89, 0xf7,
			0xe8, 0x56, 0xc8, 0x0f, 0x00,
			0x41, 0x0f, 0xb6, 0xd7,
			0x41, 0xb8, 0x00, 0x00, 0x00, 0x00,
			0x45, 0x31, 0xc9,
			0x4c, 0x8b, 0x7d, 0xa8,
			0x4c, 0x89, 0xff,
			0x4c, 0x89, 0x6d, 0x98,
			0x4c, 0x89, 0xee,
			0x8b, 0x4d, 0xd0,
			0x4c, 0x8b, 0x6d, 0xa0,
			0x41, 0x56,
			0x41, 0x54,
			0xe8, 0x4b, 0x1d, 0xed, 0xff,
			0x59,
			0x5a,
			0x49, 0x89, 0xc5,
			0x48, 0x8d, 0x05, 0xdf, 0x21, 0x22, 0x00,
			0x8b, 0x00,
			0x41, 0x3b, 0x47, 0x10,
			0x0f, 0x94, 0xc0,
			0x48, 0x8d, 0x0d, 0xc7, 0x23, 0x22, 0x00,
			0x48, 0x83, 0x79, 0x10, 0x02,
			0x0f, 0x94, 0xc1,
			0x20, 0xc1,
			0x41, 0x8b, 0xbd, 0x98, 0x00, 0x00, 0x00,
			0x41, 0x88, 0x8d, 0x98, 0x00, 0x00, 0x00,
			0xe8, 0x02, 0x14, 0xed, 0xff,
			0x49, 0x8b, 0x45, 0x78,
			0x48, 0x89, 0x43, 0x68,
			0x4c, 0x89, 0x6b, 0x60,
			0x4c, 0x8b, 0x35, 0xcf, 0xd9, 0x20, 0x00,
			0x4c, 0x89, 0xef,
			0xe8, 0x9b, 0xc7, 0x0f, 0x00,
			0x49, 0x83, 0xfe, 0xff,
			0x74, 0x13,
			0x48, 0x8d, 0x3d, 0xba, 0xd9, 0x20, 0x00,
			0x48, 0x8d, 0x35, 0x63, 0xb1, 0xf2, 0xff,
			0xe8, 0x6a, 0xc7, 0x0f, 0x00,
			0x4c, 0x8b, 0x25, 0x37, 0x28, 0x22, 0x00,
			0x4c, 0x8b, 0x3d, 0x38, 0x28, 0x22, 0x00,
			0x4c, 0x8b, 0x35, 0x39, 0x28, 0x22, 0x00,
			0x4c, 0x89, 0xf7,
			0xe8, 0xa1, 0xc7, 0x0f, 0x00,
			0x4c, 0x89, 0xe7,
			0xe8, 0x99, 0xc7, 0x0f, 0x00,
			0x4c, 0x89, 0xff,
			0xe8, 0x91, 0xc7, 0x0f, 0x00,
			0x48, 0x8d, 0x05, 0x4a, 0xec, 0x13, 0x00,
			0x48, 0xbf, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x80,
			0x48, 0x09, 0xc7,
			0x48, 0x8d, 0x85, 0x60, 0xff, 0xff, 0xff,
			0x6a, 0x19,
			0x5e,
			0x4c, 0x89, 0xe2,
			0x4c, 0x89, 0xf9,
			0x4d, 0x89, 0xf0,
			0xe8, 0x55, 0x60, 0x0f, 0x00,
			0x31, 0xff,
			0xe8, 0xce, 0x0b, 0xec, 0xff,
			0x48, 0x8b, 0x0d, 0xff, 0x2e, 0x17, 0x00,
			0x48, 0x8d, 0x7d, 0xc0,
			0x6a, 0x06,
			0x41, 0x58,
			0x48, 0x8d, 0xb5, 0x60, 0xff, 0xff, 0xff,
			0x48, 0x89, 0xc2,
			0xe8, 0x0e, 0xc6, 0x0f, 0x00,
			0x84, 0xc0,
			0x74, 0x0b,
			0xc6, 0x45, 0xc8, 0x00,
			0xf2, 0x0f, 0x10, 0x45, 0xc0,
			0xeb, 0x11,
			0x48, 0x83, 0x65, 0xc0, 0x00,
			0xc6, 0x45, 0xc8, 0x01,
			0xf2, 0x0f, 0x10, 0x05, 0xe0, 0x0a, 0x10,
			0x00,
			0xf2, 0x0f, 0x11, 0x45, 0xd0,
			0x4c, 0x89, 0xf7,
			0xe8, 0x07, 0xc7, 0x0f, 0x00,
			0x4c, 0x89, 0xff,
			0xe8, 0xff, 0xc6, 0x0f, 0x00,
			0x4c, 0x89, 0xe7,
			0xe8, 0xf7, 0xc6, 0x0f, 0x00,
			0xf2, 0x0f, 0x10, 0x45, 0xd0,
			0xf2, 0x0f, 0x11, 0x83, 0xe0, 0x00, 0x00,
			0x00,
			0x4c, 0x89, 0xef,
			0x48, 0x83, 0xc7, 0x10,
			0x48, 0x8d, 0x05, 0xe8, 0x27, 0x19, 0x00,
			0x49, 0x89, 0x45, 0x18,
			0x48, 0x89, 0xde,
			0xe8, 0xe8, 0xc6, 0x0f, 0x00,
			0x48, 0x8b, 0x7d, 0xb8,
			0xe8, 0xc7, 0xc6, 0x0f, 0x00,
			0x4c, 0x89, 0xef,
			0xe8, 0x83, 0xc6, 0x0f, 0x00,
			0x48, 0x8b, 0x7d, 0xb0,
			0xe8, 0x42, 0x0d, 0xec, 0xff,
			0x48, 0x8b, 0x7d, 0x98,
			0xe8, 0xb7, 0xc2, 0x0f, 0x00,
			0x48, 0x8b, 0x7d, 0xa8,
			0xe8, 0xa0, 0x66, 0xee, 0xff,
			0x48, 0x89, 0xd8,
			0x48, 0x83, 0xc4, 0x78,
			0x5b,
			0x41, 0x5c,
			0x41, 0x5d,
			0x41, 0x5e,
			0x41, 0x5f,
			0x5d,
			0xc3,
		),
	},
};
