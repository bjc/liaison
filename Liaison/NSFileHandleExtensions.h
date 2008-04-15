//
//  NSFileHandleExtensions.h
//  Liaison
//
//  Created by Brian Cully on Sun May 25 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#define FileHandleWriteComplete @"FileHandleWriteComplete"
#define FileHandleClosed @"FileHandleClosed"

@interface NSFileHandleExtensions : NSFileHandle
- (void)writeDataInBackground: (NSData *)someData;
@end
