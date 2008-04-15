//
//  WriterThreadPool.m
//  Liaison
//
//  Created by Brian Cully on Wed Feb 26 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "WriterThreadPool.h"

#import "WriterThread.h"

#import <signal.h>

@implementation WriterThreadPool
static WriterThreadPool *sharedPool = nil;

+ (WriterThreadPool *)sharedPool
{
    if (sharedPool == nil)
        sharedPool = [[WriterThreadPool alloc] init];
    return sharedPool;
}

void ign_handler()
{
    return;
}

- (id)init
{
    NSNotificationCenter *defaultCenter;
    struct sigaction ign_action;
    
    self = [super init];

    ign_action.sa_handler = ign_handler;
    sigemptyset(&ign_action.sa_mask);
    ign_action.sa_flags = SA_RESTART;
    sigaction(SIGPIPE, &ign_action, NULL);
    
    theWriterThreads = [[NSMutableDictionary alloc] init];

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(writerThreadDied:)
                          name: WriterThreadDied
                        object: nil];

    return self;
}

- (void)dealloc
{
    [theWriterThreads release];
    [super dealloc];
}

- (void)writeData: (NSData *)someData to: (NSFileHandle *)aFileHandle
{
    NSNumber *fd;
    WriterThread *writer;

    fd = [NSNumber numberWithInt: [aFileHandle fileDescriptor]];
    writer = [theWriterThreads objectForKey: fd];
    if (writer == nil) {
        writer = [[WriterThread alloc] initWithFileHandle: aFileHandle];
        [theWriterThreads setObject: writer forKey: fd];
        [writer release];
    }
    [writer writeData: someData];
}

- (void)killThreadFor: (NSFileHandle *)aFileHandle
{
    NSNumber *fd;
    WriterThread *writer;

    fd = [NSNumber numberWithInt: [aFileHandle fileDescriptor]];
    writer = [theWriterThreads objectForKey: fd];
    [writer die];
}

- (void)writerThreadDied: (NSNotification *)aNotification
{
    NSNumber *fd;
    WriterThread *writer;
    
    writer = [aNotification object];
        
    fd = [[aNotification userInfo] objectForKey: @"FileDescriptorKey"];
    [theWriterThreads removeObjectForKey: fd];
}
@synthesize theWriterThreads;
@end
