//
//  processes.h
//  forceFullDesktopBar
//
//  Created by moof on 10/12/15.
//  Copyright © 2015 Brian Kendall. All rights reserved.
//

#ifndef processes_h
#define processes_h

NSSet * getAllPIDsForProcessName(const char *targetName);
NSSet * getAllPIDsForProcessNameRunByUser(const char *targetName, uid_t targetUid);

#endif /* processes_h */
