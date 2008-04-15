//
//  DownloadManager.m
//  Liaison
//
//  Created by Brian Cully on Wed Jun 04 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "DownloadManager.h"
#import "Downloader.h"

@implementation DownloadManager
DownloadManager *defaultManager = nil;

+ (DownloadManager *)defaultManager
{
    if (defaultManager == nil)
        defaultManager = [[DownloadManager alloc] init];
    return defaultManager;
}

- (id)init
{
    self = [super init];

    [self setDownloads: [NSMutableDictionary dictionary]];

    return self;
}

- (void)dealloc
{
    [self setDownloads: nil];

    [super dealloc];
}

- (void)downloadFileHandle: (LiFileHandle *)aFileHandle
                fromSocket: (NSFileHandle *)aSocket
                    target: (id)anObject
         didFinishSelector: (SEL)aSelector
               withContext: (void *)someContext
{
    Downloader *downloader;

    downloader = [[Downloader alloc] initWithSocket: aSocket
                                             target: anObject
                                           selector: aSelector
                                            context: someContext];
    [[self downloads] setObject: downloader forKey: aFileHandle];
    [downloader downloadFileHandle: aFileHandle];
    [downloader release];
}
@synthesize theDownloads;
@end

@implementation DownloadManager (Accessors)
- (NSMutableDictionary *)downloads
{
    return theDownloads;
}

- (void)setDownloads: (NSMutableDictionary *)someDownloads
{
    [someDownloads retain];
    [theDownloads release];
    theDownloads = someDownloads;
}
@end