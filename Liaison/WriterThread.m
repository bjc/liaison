//
//  WriterThread.m
//  Liaison
//
//  Created by Brian Cully on Wed Feb 26 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "NSFileHandleExtensions.h"
#import "WriterThread.h"

#import <errno.h>
#import <sys/types.h>
#import <sys/uio.h>
#import <unistd.h>

#define NO_DATA 0
#define HAS_DATA 1

@implementation WriterThread
- (id)initWithFileHandle: (NSFileHandle *)aFileHandle
{
    self = [super init];

    theKillFlag = NO;
    [self setDataQueue: [NSMutableArray array]];
    [self setQueueLock:
        [[[NSConditionLock alloc] initWithCondition: NO_DATA] autorelease]];
    [self setFile: aFileHandle];

    [NSThread detachNewThreadSelector: @selector(startThreadWithObject:)
                             toTarget: self
                           withObject: nil];

    return self;
}

- (void)dealloc
{
    [self setFile: nil];
    [self setDataQueue: nil];
    [self setQueueLock: nil];
    [super dealloc];
}

- (BOOL)writeBufferedData: (NSData *)someData
{
    if (theConnectionIsOpen) {
        int fileDescriptor;
        ssize_t dataLen, wroteLen;
        void *data;

        fileDescriptor = [[self file] fileDescriptor];
        data = (void *)[someData bytes];
        dataLen = [someData length];
        wroteLen = 0;
        while (wroteLen < dataLen) {
            ssize_t rc;

            rc = write(fileDescriptor,
                       data+wroteLen,
                       dataLen-wroteLen);
            if (rc >= 0) {
                wroteLen += rc;
            } else {
                if (errno == EINTR || errno == EAGAIN)
                    continue;
                theConnectionIsOpen = NO;
                break;
            }
        }
    }

    return theConnectionIsOpen;
}

- (void)sendNextData
{
    NSData *dataToSend;
    NSNotificationCenter *defaultCenter;

    [[self queueLock] lockWhenCondition: HAS_DATA];
    if (theKillFlag || theConnectionIsOpen == NO) {
        return;
    }
    if ([[self dataQueue] count] <= 0) {
        [[self queueLock] unlockWithCondition: NO_DATA];
        [LiLog unindentDebugLog];
        return;
    }

    dataToSend = [[[[self dataQueue] objectAtIndex: 0] retain] autorelease];
    [[self dataQueue] removeObjectAtIndex: 0];
    if ([[self dataQueue] count] > 0)
        [[self queueLock] unlockWithCondition: HAS_DATA];
    else
        [[self queueLock] unlockWithCondition: NO_DATA];

    defaultCenter = [NSNotificationCenter defaultCenter];
    if ([self writeBufferedData: dataToSend] == NO) {
        NSNotification *notification;

        notification = [NSNotification notificationWithName: FileHandleClosed
                                                     object: [self file]];
        [defaultCenter performSelectorOnMainThread: @selector(postNotification:)
                                        withObject: notification
                                     waitUntilDone: YES];
    } else {
        NSNotification *notification;

        notification = [NSNotification notificationWithName: FileHandleWriteComplete
                                                     object: [self file]];
        [defaultCenter performSelectorOnMainThread: @selector(postNotification:)
                                        withObject: notification
                                     waitUntilDone: NO];
    }
}

- (void)startThreadWithObject: (id)anObject
{
    NSAutoreleasePool *rp;
    NSDictionary *userInfo;
    NSNotification *notification;
    NSNotificationCenter *defaultCenter;
    NSNumber *fd;
    
    rp = [[NSAutoreleasePool alloc] init];

    fd = [NSNumber numberWithInt: [[self file] fileDescriptor]];
    theConnectionIsOpen = YES;
    while (theKillFlag == NO) {
        NSAutoreleasePool *srp;
        
        srp = [[NSAutoreleasePool alloc] init];
        [self sendNextData];
        [srp release];
    }

    userInfo = [NSDictionary dictionaryWithObject: fd
                                           forKey: @"FileDescriptorKey"];
    defaultCenter = [NSNotificationCenter defaultCenter];
    notification = [NSNotification notificationWithName: WriterThreadDied
                                                 object: self
                                               userInfo: userInfo];
    [defaultCenter performSelectorOnMainThread: @selector(postNotification:)
                                    withObject: notification
                                 waitUntilDone: YES];
    [rp release];
}

- (void)die
{
    [[self queueLock] lock];
    theKillFlag = YES;
    [[self queueLock] unlockWithCondition: HAS_DATA];
}

- (void)writeData: (NSData *)someData
{
    if (someData == nil)
        return;

    [[self queueLock] lock];
    NS_DURING
        [[self dataQueue] addObject: someData];
    NS_HANDLER
        [LiLog logAsDebug: @"Got exception '%@' trying to add to data queue: %@.", [localException name], [localException reason]];
    NS_ENDHANDLER
    [[self queueLock] unlockWithCondition: HAS_DATA];
}
@synthesize theQueueLock;
@synthesize theConnectionIsOpen;
@synthesize theKillFlag;
@synthesize theDataQueue;
@end

@implementation WriterThread (Accessors)
- (NSMutableArray *)dataQueue
{
    return theDataQueue;
}

- (void)setDataQueue: (NSMutableArray *)aQueue
{
    [aQueue retain];
    [theDataQueue release];
    theDataQueue = aQueue;
}

- (NSConditionLock *)queueLock
{
    return theQueueLock;
}

- (void)setQueueLock: (NSConditionLock *)aLock
{
    [aLock retain];
    [theQueueLock release];
    theQueueLock = aLock;
}

- (NSFileHandle *)file
{
    return theFile;
}

- (void)setFile: (NSFileHandle *)aFile
{
    theFile = aFile;
}
@end