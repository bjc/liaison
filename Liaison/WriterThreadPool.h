//
//  WriterThreadPool.h
//  Liaison
//
//  Created by Brian Cully on Wed Feb 26 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface WriterThreadPool : NSObject {
    NSMutableDictionary *theWriterThreads;
}
+ (WriterThreadPool *)sharedPool;

- (void)writeData: (NSData *)someData to: (NSFileHandle *)aFileHandle;
- (void)killThreadFor: (NSFileHandle *)aFileHandle;
@property (retain) NSMutableDictionary *theWriterThreads;
@end
