//
//  NSFileHandleExtensions.m
//  Liaison
//
//  Created by Brian Cully on Sun May 25 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "NSFileHandleExtensions.h"

#import "WriterThreadPool.h"

@implementation NSFileHandleExtensions
- (void)dealloc
{
    [[WriterThreadPool sharedPool] killThreadFor: self];
    [super dealloc];
}

- (void)writeDataInBackground: (NSData *)someData
{
    [[WriterThreadPool sharedPool] writeData: someData to: self];
}
@end
