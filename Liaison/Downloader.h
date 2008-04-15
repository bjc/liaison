//
//  Downloader.h
//  Liaison
//
//  Created by Brian Cully on Fri Jun 06 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@class DownloadStatusView;

@interface Downloader : NSObject
{
    DownloadStatusView *theStatusView;
    LiFileHandle *theRemoteFileHandle;
    NSDictionary *theFileAttributes;
    NSFileHandle *theSocket;
    NSFileHandle *theLocalFile;
    NSString *theLocalFilePath;
    void *theCallbackContext;
    id theCallbackTarget;
    SEL theCallbackSelector;

    unsigned long theBytesInLocalFile;
}
- (id)initWithSocket: (NSFileHandle *)aSocket
              target: (id)aTarget
            selector: (SEL)aSelector
             context: (void *)someContext;

- (void)downloadFileHandle: (LiFileHandle *)aFileHandle;
@property (retain,getter=localFilePath) NSString *theLocalFilePath;
@property (getter=callbackContext,setter=setCallbackContext:) void *theCallbackContext;
@property (retain,getter=statusView) DownloadStatusView *theStatusView;
@property (getter=callbackSelector,setter=setCallbackSelector:) SEL theCallbackSelector;
@property (retain,getter=socket) NSFileHandle *theSocket;
@property (retain,getter=callbackTarget) id theCallbackTarget;
@property (retain,getter=fileAttributes) NSDictionary *theFileAttributes;
@property (retain,getter=remoteFileHandle) LiFileHandle *theRemoteFileHandle;
@property (retain,getter=localFile) NSFileHandle *theLocalFile;
@property unsigned long theBytesInLocalFile;
@end

@interface Downloader (Accessors)
- (LiFileHandle *)remoteFileHandle;
- (void)setRemoteFileHandle: (LiFileHandle *)aFileHandle;
- (NSFileHandle *)localFile;
- (void)setLocalFile: (NSFileHandle *)aFile;
- (NSString *)localFilePath;
- (void)setLocalFilePath: (NSString *)aPath;
- (DownloadStatusView *)statusView;
- (void)setStatusView: (DownloadStatusView *)aStatusView;

- (NSDictionary *)fileAttributes;
- (void)setFileAttributes: (NSDictionary *)someAttributes;
- (NSFileHandle *)socket;
- (void)setSocket: (NSFileHandle *)aSocket;
- (id)callbackTarget;
- (void)setCallbackTarget: (id)aTarget;
- (SEL)callbackSelector;
- (void)setCallbackSelector: (SEL)aSelector;
- (void *)callbackContext;
- (void)setCallbackContext: (void *)someContext;
@end