//
//  ServerManager.m
//  Liaison
//
//  Created by Brian Cully on Sun Feb 16 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//
#import "RenIPC.h"
#import "ServerManager.h"

#import "CopyController.h"
#import "DownloadStatusView.h"
#import "DownloadManager.h"
#import "LiDataTranslator.h"
#import "NIBConnector.h"

#import <netinet/in.h>
#import <sys/socket.h>
#import <unistd.h>

@interface ServerManager (NetworkStuff)
- (BOOL)sendCommand: (NSDictionary *)aCmd;
@end

@interface NSNetService (FileHandleExtensions)
- (NSFileHandle *)fileHandle;
@end

@implementation ServerManager
+ (NSImage *)fileStoreIcon
{
    NSImage *image;
    NSString *iconPath;

    image = [NSImage imageNamed: @"LiBuiltInFunctions RenStoreIcon"];
    if (image == nil) {
        iconPath = [[NSBundle bundleForClass: [self class]] pathForResource: @"rendezvous" ofType: @"tiff"];
        image = [[NSImage alloc] initWithContentsOfFile: iconPath];
        [image setName: @"LiBuiltInFunctions RenStoreIcon"];
    }

    return image;
}

- (id)initWithNetService: (NSNetService *)aService
{
    NSBundle *myBundle;
    
    self = [super init];

    [self setService: aService];
    [self setFile: [[self service] fileHandle]];
    if ([self file] == nil) {
        [self autorelease];
        return nil;
    }
    [self setFileStore: [LiFileStore fileStoreWithName: [aService name]]];
    [[self fileStore] setEditable: NO];
    [[self fileStore] setIcon: [[self class] fileStoreIcon]];
    [[self fileStore] setDelegate: self];
    [[self fileStore] addIndexForAttribute: LiGroupsAttribute];
    
    theBuffer = [[NSMutableData alloc] init];

    myBundle = [NSBundle bundleForClass: [self class]];

    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    [LiLog logAsDebug: @"[ServerManager dealloc]"];
    
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];

    [self setService: nil];
    [self setFile: nil];
    [self setFileStore: nil];
    [self setBuffer: nil];

    [super dealloc];
}

- (void)startup
{
    NSDictionary *handshake;
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(browserRead:)
                          name: NSFileHandleReadCompletionNotification
                        object: [self file]];

    handshake = [NSDictionary dictionaryWithObject: @"browser"
                                            forKey: @"type"];
    [self sendCommand: handshake];
    
    [[self file] readInBackgroundAndNotify];
}

- (void)shutdown
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self
                             name: NSFileHandleReadCompletionNotification
                           object: [self file]];

    [LiFileStore removeStoreWithID: [[self fileStore] storeID]];
    [self setFile: nil];
    [self setFileStore: nil];

    [defaultCenter postNotificationName: SERVERMANAGERDEATHNOTIFICATION
                                 object: self
                               userInfo: nil];
}
@synthesize theBuffer;
@synthesize theFileStore;
@synthesize theFile;
@synthesize theService;
@end

@implementation ServerManager (Accessors)
- (NSFileHandle *)file
{
    return theFile;
}

- (void)setFile: (NSFileHandle *)aFile
{
    [aFile retain];
    [theFile release];
    theFile = aFile;
}

- (NSNetService *)service
{
    return theService;
}

- (void)setService: (NSNetService *)aService
{
    [aService retain];
    [theService release];
    theService = aService;
}

- (NSMutableData *)buffer
{
    return theBuffer;
}

- (void)setBuffer: (NSMutableData *)aBuffer
{
    [aBuffer retain];
    [theBuffer release];
    theBuffer = aBuffer;
}

- (LiFileStore *)fileStore
{
    return theFileStore;
}

- (void)setFileStore: (LiFileStore *)aFileStore
{
    [aFileStore retain];
    [theFileStore release];
    theFileStore = aFileStore;
}
@end

@implementation ServerManager (LiFileStore)
- (BOOL)synchronizeFileStore
{
    return YES;
}

- (void)synchronizeFileHandle: (LiFileHandle *)aFileHandle
            withNewAttributes: (NSMutableDictionary *)someAttributes
{
}

- (BOOL)shouldUpdateFileHandle: (LiFileHandle *)aFileHandle
{
    return NO;
}

- (void)updateFileHandle: (LiFileHandle *)aFileHandle
{
    return;
}

- (void)openFileHandle: (LiFileHandle *)aFileHandle
{
    NSFileHandle *copySocket;

    [LiLog logAsDebug: @"[ServerManager openFileHandle: %@]", aFileHandle];
    [LiLog indentDebugLog];

    [LiLog logAsDebug: @"filename: %@", [aFileHandle filename]];
    copySocket = [[self service] fileHandle];
    [[DownloadManager defaultManager] downloadFileHandle: aFileHandle
                                              fromSocket: copySocket
                                                  target: self
                                       didFinishSelector: @selector(fileHandleFinishedDownloading:context:errorString:)
                                             withContext: nil];
    [LiLog unindentDebugLog];
}

- (void)fileHandleFinishedDownloading: (LiFileHandle *)aFileHandle
                              context: (void *)someContext
                          errorString: (NSString *)anError
{
    [LiLog logAsDebug: @"[ServerManager fileHandleFinishedDownloading]"];
    [LiLog indentDebugLog];
    if (anError != nil) {
        [LiLog logAsError: @"Couldn't download %@: %@",
            [aFileHandle filename], anError];
    } else {
        [LiLog logAsDebug: @"File downloaded successfully."];
    }
    [LiLog unindentDebugLog];
}

- (LiFileHandle *)addURL: (NSURL *)anURL
             toFileStore: (LiFileStore *)aFileStore
{
    return nil;
}

- (NSURL *)urlForFileHandle: (LiFileHandle *)aFileHandle
{
    NSURL *url;
    NSString *urlStr;

    urlStr = [NSString stringWithFormat: @"liaison://%@/%@", [[aFileHandle fileStore] name], [aFileHandle fileID]];
    url = [NSURL URLWithString: urlStr];
    return url;
}

- (NSArray *)defaultValuesForAttribute: (NSString *)anAttribute
{
    return nil;
}

- (BOOL)addDefaultAttribute: (NSDictionary *)anAttribute toFileStore: (LiFileStore *)aFileStore
{
    return NO;
}

- (BOOL)changeDefaultValueForAttribute: (NSDictionary *)anAttribute toValue: (id)aValue inFileStore: (LiFileStore *)aFileStore
{
    return NO;
}

- (BOOL)removeDefaultAttribute: (NSDictionary *)anAttribute fromFileStore: (LiFileStore *)aFileStore
{
    return NO;
}
@end

@implementation ServerManager (NetworkStuff)
- (BOOL)sendCommand: (NSDictionary *)aCmd
{
    NSData *cmdData;
    NSString *errorString;

    errorString = nil;
    cmdData = [aCmd encodedData];
    if (cmdData != nil) {
        [[self file] writeData: cmdData];
        return YES;
    } else
        return NO;
}

- (void)processAddList: (NSArray *)changeList
{
    NSDictionary *fileInfo;

    for (fileInfo in changeList) {
        LiFileHandle *file;

        file = [[self fileStore] addFileWithAttributes: fileInfo];
    }

    [[self fileStore] synchronize];
}

- (void)processChangeList: (NSArray *)aFileList
{
    NSDictionary *changeDict;

    for (changeDict in aFileList) {
        id fileID;

        fileID = [changeDict objectForKey: LiFileHandleAttribute];
        if (fileID != nil) {
            LiFileHandle *tmpHandle;
            NSEnumerator *attrEnum;
            NSString *attribute;

            tmpHandle = [[LiFileHandle alloc] init];
            [tmpHandle setFileStore: [self fileStore]];
            [tmpHandle setFileID: fileID];

            attrEnum = [changeDict keyEnumerator];
            while ((attribute = [attrEnum nextObject]) != nil) {
                if ([attribute compare: LiFileHandleAttribute] != 0) {
                    [tmpHandle setValue: [changeDict objectForKey: attribute]
                           forAttribute: attribute];
                }
            }

            [tmpHandle release];
        }
    }

    [[self fileStore] synchronize];
}

- (void)processDeleteList: (NSArray *)aFileList
{
    id fileID;

    for (fileID in aFileList) {
        LiFileHandle *tmpFile;

        tmpFile = [[LiFileHandle alloc] init];
        [tmpFile setFileStore: [self fileStore]];
        [tmpFile setFileID: fileID];

        [[self fileStore] removeFileHandle: tmpFile];
        [tmpFile release];
    }

    [[self fileStore] synchronize];
}

- (void)processServerMessage: (NSDictionary *)aMsg
{
    NSString *msgType;
    id arg;

    msgType = [aMsg objectForKey: @"type"];
    arg = [aMsg objectForKey: @"arg"];
    if ([msgType isEqualToString: RenHostnameKey]) {
        [[self fileStore] setName: arg];
    } else if ([msgType isEqualToString: RenFilesAddedKey]) {
        [self processAddList: arg];
    } else if ([msgType isEqualToString: RenFilesChangedKey]) {
        [self processChangeList: arg];
    } else if ([msgType isEqualToString: RenFilesRemovedKey]) {
        [self processDeleteList: arg];
    } else {
        [LiLog logAsError: @"Unknown server message type: '%@'.", msgType];
    }
}

- (void)processData: (NSData *)someData
{
    NSDictionary *msg;

    [[self buffer] appendData: someData];
    msg = [NSDictionary dictionaryWithEncodedData: [self buffer]];
    if (msg != nil) {
        [self setBuffer: [NSMutableData data]];
        [self processServerMessage: msg];
    }
}

- (void)browserRead: (NSNotification *)aNotification
{
    NSData *data;
    NSFileHandle *remoteSocket;

    remoteSocket = [aNotification object];
    data = [[aNotification userInfo] objectForKey:
        NSFileHandleNotificationDataItem];
    if ([data length] > 0)
        [self processData: data];
    else {
        [LiLog logAsDebug: @"browserRead shutdown"];
        [self shutdown];
    }

    [[aNotification object] readInBackgroundAndNotify];
}
@end

@implementation NSNetService (FileHandleExtensions)
- (NSFileHandle *)fileHandle
{
    NSArray *serverAddresses;
    NSData *data;
    NSFileHandle *remoteSocket;
    struct sockaddr_in *remoteAddr;
    int remotePort, rc;

    serverAddresses = [self addresses];
    if ([serverAddresses count] <= 0)
        return nil;

    data = [serverAddresses objectAtIndex: 0];
    remoteAddr = (struct sockaddr_in *)[data bytes];

    remotePort = socket(AF_INET, SOCK_STREAM, 0);
    remoteSocket = [[NSFileHandle alloc] initWithFileDescriptor: remotePort
                                                 closeOnDealloc: YES];
    [remoteSocket autorelease];

    rc = connect(remotePort,
                 (struct sockaddr *)remoteAddr,
                 sizeof(*remoteAddr));
    if (rc == -1) {
        [LiLog logAsWarning: @"couldn't connect to %@: %s.", [self name], strerror(errno)];
        return nil;
    }

    return remoteSocket;
}
@end