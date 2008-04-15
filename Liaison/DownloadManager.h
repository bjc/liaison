//
//  DownloadManager.h
//  Liaison
//
//  Created by Brian Cully on Wed Jun 04 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface DownloadManager : NSObject
{
    NSMutableDictionary *theDownloads;
}
// The default download manager.
+ (DownloadManager *)defaultManager;

// Tell the manager to download a file. When it's finished, it'll
// call the selector, if it's there, and if context is supplied,
// it'll be passed on to the selector as well.
// The selector should have the following signature:
// - (void)fileHandleFinishedDownloading: (LiFileHandle *)aFileHandle
//                               context: (void *)someContext
//                           errorString: (NSString *)anError
// If errorString isn't nil, then the file did not finish downloading
// properly, either by user action or by some other error.
- (void)downloadFileHandle: (LiFileHandle *)aFileHandle
                fromSocket: (NSFileHandle *)aSocket
                    target: (id)anObject
         didFinishSelector: (SEL)aSelector
               withContext: (void *)someContext;
@property (retain,getter=downloads) NSMutableDictionary *theDownloads;
@end

@interface DownloadManager (Accessors)
- (NSMutableDictionary *)downloads;
- (void)setDownloads: (NSMutableDictionary *)someDownloads;
@end