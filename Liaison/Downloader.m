//
//  Downloader.m
//  Liaison
//
//  Created by Brian Cully on Fri Jun 06 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "Downloader.h"

#import "CopyController.h"
#import "DownloadStatusView.h"
#import "LiDataTranslator.h"
#import "NIBConnector.h"

@interface Downloader (NetworkStuff)
- (void)errorMsg: (NSString *)aMsg;
- (void)beginCopy;
- (void)shutdown;
@end

@implementation Downloader
- (id)initWithSocket: (NSFileHandle *)aSocket
              target: (id)aTarget
            selector: (SEL)aSelector
             context: (void *)someContext
{
    self = [super init];

    [self setSocket: aSocket];
    [self setCallbackTarget: aTarget];
    [self setCallbackSelector: aSelector];
    [self setCallbackContext: someContext];
    
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];
    
    [self setSocket: nil];
    [self setCallbackTarget: nil];
    [self setCallbackSelector: nil];
    [self setCallbackContext: nil];

    [super dealloc];
}

- (void)downloadFileHandle: (LiFileHandle *)aFileHandle
{
    NSFileManager *defaultManager;
    NSString *filename, *type, *path;
    
    filename = [aFileHandle filename];
    type = [aFileHandle type];
    if ([type length] > 0)
        filename = [filename stringByAppendingPathExtension: type];
    
    path = [[[Preferences sharedPreferences] downloadDirectory]
        stringByAppendingPathComponent: filename];
    [self setLocalFilePath: path];

    defaultManager = [NSFileManager defaultManager];
    if ([defaultManager createFileAtPath: path
                                contents: nil
                              attributes: nil]) {
        NSFileHandle *tmpFile;

        tmpFile = [NSFileHandle fileHandleForWritingAtPath: path];
        [self setLocalFile: tmpFile];

        [self setRemoteFileHandle: aFileHandle];
        [self setFileAttributes:
            [[aFileHandle fileStore] attributesForFileHandle: aFileHandle]];
        [self beginCopy];
    } else {
        NSString *errorMsg;

        errorMsg = [NSString stringWithFormat:
                       @"couldn't write to %@: %@", path, strerror(errno)];
        [self errorMsg: errorMsg];
    }
}
@synthesize theBytesInLocalFile;
@synthesize theLocalFilePath;
@synthesize theFileAttributes;
@synthesize theRemoteFileHandle;
@synthesize theLocalFile;
@synthesize theStatusView;
@synthesize theCallbackTarget;
@synthesize theSocket;
@end

@implementation Downloader (Accessors)
- (LiFileHandle *)remoteFileHandle
{
    return theRemoteFileHandle;
}

- (void)setRemoteFileHandle: (LiFileHandle *)aFileHandle
{
    [aFileHandle retain];
    [theRemoteFileHandle release];
    theRemoteFileHandle = aFileHandle;
}

- (NSFileHandle *)localFile
{
    return theLocalFile;
}

- (void)setLocalFile: (NSFileHandle *)aFile
{
    [aFile retain];
    [theLocalFile release];
    theLocalFile = aFile;
}

- (NSString *)localFilePath
{
    return theLocalFilePath;
}

- (void)setLocalFilePath: (NSString *)aPath
{
    [aPath retain];
    [theLocalFilePath release];
    theLocalFilePath = aPath;
}

- (DownloadStatusView *)statusView
{
    return theStatusView;
}

- (void)setStatusView: (DownloadStatusView *)aStatusView
{
    [aStatusView retain];
    [theStatusView release];
    theStatusView = aStatusView;
}

- (NSDictionary *)fileAttributes
{
    return theFileAttributes;
}

- (void)setFileAttributes: (NSDictionary *)someAttributes
{
    [someAttributes retain];
    [theFileAttributes release];
    theFileAttributes = someAttributes;
}

- (NSFileHandle *)socket
{
    return theSocket;
}

- (void)setSocket: (NSFileHandle *)aSocket
{
    [aSocket retain];
    [theSocket release];
    theSocket = aSocket;
}

- (id)callbackTarget
{
    return theCallbackTarget;
}

- (void)setCallbackTarget: (id)aTarget
{
    [aTarget retain];
    [theCallbackTarget release];
    theCallbackTarget = aTarget;
}

- (SEL)callbackSelector
{
    return theCallbackSelector;
}

- (void)setCallbackSelector: (SEL)aSelector
{
    theCallbackSelector = aSelector;
}

- (void *)callbackContext
{
    return theCallbackContext;
}

- (void)setCallbackContext: (void *)someContext
{
    theCallbackContext = someContext;
}
@end

@implementation Downloader (NetworkStuff)
- (NSImage *)cancelImage
{
    NSBundle *myBundle;
    NSString *tmpPath;
    NSImage *tmpImage;
    
    myBundle = [NSBundle bundleForClass: [self class]];
    tmpPath = [myBundle pathForImageResource: @"Download_Stop.tiff"];
    tmpImage = [[NSImage alloc] initWithContentsOfFile: tmpPath];
    return [tmpImage autorelease];
}

- (NSImage *)cancelImagePressed
{
    NSBundle *myBundle;
    NSString *tmpPath;
    NSImage *tmpImage;
    
    myBundle = [NSBundle bundleForClass: [self class]];
    tmpPath = [myBundle pathForImageResource: @"Download_StopPressed.tiff"];
    tmpImage = [[NSImage alloc] initWithContentsOfFile: tmpPath];
    return [tmpImage autorelease];
}

- (NSImage *)reloadImage
{
    NSBundle *myBundle;
    NSString *tmpPath;
    NSImage *tmpImage;
    
    myBundle = [NSBundle bundleForClass: [self class]];
    tmpPath = [myBundle pathForImageResource: @"Download_Reload.tiff"];
    tmpImage = [[NSImage alloc] initWithContentsOfFile: tmpPath];
    return [tmpImage autorelease];
}

- (NSImage *)reloadImagePressed
{
    NSBundle *myBundle;
    NSString *tmpPath;
    NSImage *tmpImage;
    
    myBundle = [NSBundle bundleForClass: [self class]];
    tmpPath = [myBundle pathForImageResource: @"Download_ReloadPressed.tiff"];
    tmpImage = [[NSImage alloc] initWithContentsOfFile: tmpPath];
    return [tmpImage autorelease];
}

- (NSImage *)revealImage
{
    NSBundle *myBundle;
    NSString *tmpPath;
    NSImage *tmpImage;
    
    myBundle = [NSBundle bundleForClass: [self class]];
    tmpPath = [myBundle pathForImageResource: @"Download_Reveal.tiff"];
    tmpImage = [[NSImage alloc] initWithContentsOfFile: tmpPath];
    return [tmpImage autorelease];
}

- (NSImage *)revealImagePressed
{
    NSBundle *myBundle;
    NSString *tmpPath;
    NSImage *tmpImage;
    
    myBundle = [NSBundle bundleForClass: [self class]];
    tmpPath = [myBundle pathForImageResource: @"Download_RevealPressed.tiff"];
    tmpImage = [[NSImage alloc] initWithContentsOfFile: tmpPath];
    return [tmpImage autorelease];
}

- (void)setupStatusViewForFileHandle: (LiFileHandle *)aFileHandle
{
    DownloadStatusView *statusView;
    NSImage *fileIcon;

    fileIcon = [[NSWorkspace sharedWorkspace] iconForFileType:
        [aFileHandle type]];
    [fileIcon setSize: NSMakeSize(32.0, 32.0)];

    statusView = [[[NIBConnector connector] copyController] statusViewForFileHandle: aFileHandle];
    [statusView setFilename: [aFileHandle filename]];
    [statusView setIcon: fileIcon];
    [statusView setProgress: 0.0];
    [statusView setButtonImage: [self cancelImage]];
    [statusView setButtonAltImage: [self cancelImagePressed]];
    [statusView setButtonTarget: self];
    [statusView setButtonAction: @selector(cancelCopy)];
    [self setStatusView: statusView];
}

- (void)errorMsg: (NSString *)aMsg
{
    id target;

    [self shutdown];
    
    target = [self callbackTarget];
    if (target != nil) {
        SEL callbackSelector;

        callbackSelector = [self callbackSelector];
        if (callbackSelector != nil) {
            IMP callback;
            void *context;

            context = [self callbackContext];
            callback = [target methodForSelector: callbackSelector];
            if (callback != nil)
                callback(target, callbackSelector,
                         [self remoteFileHandle], context, aMsg);
        }
    }
}

- (BOOL)sendCommand: (NSDictionary *)aCmd
{
    NSData *cmdData;

    cmdData = [aCmd encodedData];
    if (cmdData != nil) {
        [[self socket] writeData: cmdData];
        return YES;
    } else
        return NO;
}

- (void)beginCopy
{
    NSDictionary *copyCmd;
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(gotCopyData:)
                          name: NSFileHandleReadCompletionNotification
                        object: [self socket]];

    [self setupStatusViewForFileHandle: [self remoteFileHandle]];
    
    copyCmd = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects: @"download",
            [[self remoteFileHandle] fileID], nil]
                                          forKeys:
        [NSArray arrayWithObjects: @"type",
            @"LiFileHandleAttribute", nil]];
    [self sendCommand: copyCmd];

    theBytesInLocalFile = 0;
    [[self socket] readInBackgroundAndNotify];
}

- (void)gotCopyData: (NSNotification *)aNotification
{
    NSData *fileData;
    double totalLength, progress;

    fileData = [[aNotification userInfo] objectForKey:
        NSFileHandleNotificationDataItem];

    totalLength = [[[self fileAttributes] objectForKey: LiFileSizeAttribute] doubleValue];
    theBytesInLocalFile += [fileData length];
    if ([fileData length] > 0 && theBytesInLocalFile < totalLength) {
        [[self localFile] writeData: fileData];

        if (totalLength > 0) {
            progress = theBytesInLocalFile / totalLength;
            [[self statusView] setProgress: progress];
        }

        [[self socket] readInBackgroundAndNotify];
    } else {
        DownloadStatusView *statusView;

        [self shutdown];

        statusView = [self statusView];
        [statusView setButtonImage: [self revealImage]];
        [statusView setButtonAltImage: [self revealImagePressed]];
        [statusView setButtonTarget: self];
        [statusView setButtonAction: @selector(revealInFinder)];
        [statusView setProgress: 1.0];
    }
}

- (void)cancelCopy
{
    DownloadStatusView *statusView;
    NSFileManager *defaultManager;

    defaultManager = [NSFileManager defaultManager];
    [defaultManager removeFileAtPath: [self localFilePath]
                             handler: nil];

    [self shutdown];
    
    statusView = [self statusView];
    [statusView setButtonImage: [self reloadImage]];
    [statusView setButtonAltImage: [self reloadImagePressed]];
    [statusView setButtonTarget: [self remoteFileHandle]];
    [statusView setButtonAction: @selector(open)];
    [statusView setProgress: 0.0];
}

- (void)shutdown
{
    NSNotificationCenter *defaultCenter;
    
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self
                             name: NSFileHandleReadCompletionNotification
                           object: [self socket]];
    
    [self setLocalFile: nil];
    [self setSocket: nil];
}

- (void)revealInFinder
{
    if ([self localFilePath] != nil) {
        [[NSWorkspace sharedWorkspace] selectFile: [self localFilePath] inFileViewerRootedAtPath: @""];
    }
}
@end