//
//  WriterThread.h
//  Liaison
//
//  Created by Brian Cully on Wed Feb 26 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#define WriterThreadDied @"LiWriterThreadDied"

@interface WriterThread : NSObject {
    NSMutableArray *theDataQueue;
    NSConditionLock *theQueueLock;

    NSFileHandle *theFile;

    volatile BOOL theConnectionIsOpen;
    volatile BOOL theKillFlag;
}
- (id)initWithFileHandle: (NSFileHandle *)aFileHandle;
- (void)die;

- (void)writeData: (NSData *)someData;
@property (retain,getter=queueLock) NSConditionLock *theQueueLock;
@property (retain,getter=dataQueue) NSMutableArray *theDataQueue;
@property volatile BOOL theConnectionIsOpen;
@property volatile BOOL theKillFlag;
@property (assign,getter=file,setter=setFile:) NSFileHandle *theFile;
@end

@interface WriterThread (Accessors)
- (NSMutableArray *)dataQueue;
- (void)setDataQueue: (NSMutableArray *)aQueue;
- (NSConditionLock *)queueLock;
- (void)setQueueLock: (NSConditionLock *)aLock;
- (NSFileHandle *)file;
- (void)setFile: (NSFileHandle *)aFile;
@end
