//
//  ClientManager.m
//  Liaison
//
//  Created by Brian Cully on Sun Feb 16 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//
#import "ClientManager.h"

#import "LiDataTranslator.h"
#import "RenIPC.h"

#import <netinet/in.h>
#import <string.h>
#import <sys/socket.h>
#import <unistd.h>

@interface ClientManager (Downloader)
- (void)startCopyOfFileHandle: (LiFileHandle *)aFileHandle;
@end

@implementation ClientManager
- (BOOL)sendCommand: (NSDictionary *)aCmd
{
    NSData *cmdData;

    cmdData = [aCmd encodedData];
    if (cmdData != nil) {
        [(NSFileHandleExtensions *)[self file] writeDataInBackground: cmdData];
        return YES;
    } else
        return NO;
}

- (NSDictionary *)processData: (NSData *)someData
{
    NSDictionary *msg;
    
    [[self buffer] appendData: someData];
    msg = [NSDictionary dictionaryWithEncodedData: [self buffer]];
    if (msg != nil)
        [self setBuffer: [NSMutableData data]];
    return msg;
}

- (id)initWithFile: (NSFileHandle *)aFile
      andFileStore: (LiFileStore *)aFileStore
{
    NSNotificationCenter *defaultCenter;
    
    self = [super init];

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(remoteClosed:)
                          name: FileHandleClosed
                        object: aFile];

    [self setFile: aFile];
    [self setFileStore: aFileStore];
    [self setCopyFile: nil];
    [self setBuffer: [NSMutableData data]];

    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    [LiLog logAsDebug: @"[ClientManager dealloc]"];
    
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];

    [self setFile: nil];
    [self setFileStore: nil];
    [self setCopyFile: nil];
    [self setBuffer: nil];

    [super dealloc];
}

- (void)startup
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(doHandshake:)
                          name: NSFileHandleReadCompletionNotification
                        object: [self file]];
    [[self file] readInBackgroundAndNotify];
}

- (BOOL)filePassesFilter: (LiFileHandle *)aFileHandle
    withCustomAttributes: (NSDictionary *)someAttrs
{
    NSArray *groups;
    
    if ([aFileHandle url] == nil || [[aFileHandle url] isFileURL] == NO)
        return NO;
    
    groups = [someAttrs objectForKey: LiGroupsAttribute];
    if (groups != nil) {
        return [groups count] > 0;
    } else {
        return [[aFileHandle groups] count] > 0;
    }
}

- (BOOL)filePassesFilter: (LiFileHandle *)aFileHandle
{
    return [self filePassesFilter: aFileHandle
             withCustomAttributes: nil];
}

- (NSMutableDictionary *)filteredAttributesForAttributes:
    (NSDictionary *)someAttrs
{
    NSMutableDictionary *filteredAttributes;
    
    [LiLog indentDebugLog];
    filteredAttributes = [NSMutableDictionary dictionaryWithDictionary: someAttrs];
    [filteredAttributes setObject: [NSNumber numberWithBool: NO]
                           forKey: LiIsEditableAttribute];
    [filteredAttributes removeObjectForKey: LiDirectoryAttribute];
    [filteredAttributes removeObjectForKey: LiApplicationAttribute];
    [filteredAttributes removeObjectForKey: @"LiAliasAttribute"];
    
    [LiLog unindentDebugLog];

    return filteredAttributes;
}

- (NSMutableDictionary *)filteredAttributesForFileHandle:
    (LiFileHandle *)aFileHandle
{
    return [self filteredAttributesForAttributes: [[aFileHandle fileStore] attributesForFileHandle: aFileHandle]];
}

- (void)sendFileList: (NSArray *)aFileList
{
    LiFileHandle *file;
    NSMutableArray *filteredChanges;

    [LiLog logAsDebug: @"Filtering file list."];
    filteredChanges = [[NSMutableArray alloc] init];
    for (file in aFileList) {
        if ([self filePassesFilter: file]) {
            NSDictionary *fileAttrs;

            fileAttrs = [self filteredAttributesForFileHandle: file];
            [filteredChanges addObject: fileAttrs];
        }
    }
    [LiLog logAsDebug: @"Done filtering file list."];

    if ([filteredChanges count] > 0) {
        NSDictionary *tmpDict;

        [LiLog logAsDebug: @"Creating command dictionary."];
        tmpDict = [NSDictionary dictionaryWithObjects:
            [NSArray arrayWithObjects: RenFilesAddedKey, filteredChanges, nil]
                                              forKeys:
            [NSArray arrayWithObjects: @"type", @"arg", nil]];
        [LiLog logAsDebug: @"Done creating command dictionary."];
        [self sendCommand: tmpDict];
    }
}

- (void)sendDeleteList: (NSArray *)aFileList
{
    NSDictionary *fileInfo;
    NSMutableArray *deleteList;

    deleteList = [NSMutableArray array];
    for (fileInfo in aFileList) {
        LiFileHandle *file;
        NSDictionary *oldAttributes;

        file = [fileInfo objectForKey: LiFileHandleAttribute];
        oldAttributes = [fileInfo objectForKey: LiFileOldAttributes];
        if ([self filePassesFilter: file
              withCustomAttributes: oldAttributes]) {
            [deleteList addObject: [file fileID]];
        }
    }

    if ([deleteList count] > 0) {
        NSDictionary *tmpDict;

        tmpDict = [NSDictionary dictionaryWithObjects:
            [NSArray arrayWithObjects: RenFilesRemovedKey, deleteList, nil]
                                              forKeys:
            [NSArray arrayWithObjects: @"type", @"arg", nil]];
        [self sendCommand: tmpDict];
    }
}

- (void)sendChangeList: (NSArray *)aFileList
{
    NSDictionary *changeDict, *fileInfo;
    NSMutableArray *changeList, *addList, *deleteList;

    changeList = [NSMutableArray array];
    addList = [NSMutableArray array];
    deleteList = [NSMutableArray array];
    for (fileInfo in aFileList) {
        LiFileHandle *file;
        NSDictionary *oldAttributes;

        file = [fileInfo objectForKey: LiFileHandleAttribute];
        oldAttributes = [fileInfo objectForKey: LiFileOldAttributes];
        if ([self filePassesFilter: file
              withCustomAttributes: oldAttributes]) {
            NSDictionary *fileAttrs;

            if ([self filePassesFilter: file]) {
                NSEnumerator *attrEnum;
                NSMutableDictionary *filtAttrs;
                NSString *attr;

                filtAttrs = [[NSMutableDictionary alloc] init];
                fileAttrs = [self filteredAttributesForAttributes: oldAttributes];
                attrEnum = [oldAttributes keyEnumerator];
                while ((attr = [attrEnum nextObject]) != nil) {
                    [filtAttrs setObject: [file valueForAttribute: attr]
                                  forKey: attr];
                }
                [filtAttrs setObject: [file fileID]
                              forKey: LiFileHandleAttribute];
                [changeList addObject: filtAttrs];
                [filtAttrs release];
            } else
                [deleteList addObject:
                    [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects: file, oldAttributes, nil]
                                                forKeys:
                        [NSArray arrayWithObjects: LiFileHandleAttribute, LiFileOldAttributes, nil]]];
        } else if ([self filePassesFilter: file])
            [addList addObject: file];
    }
    [self sendDeleteList: deleteList];
    [self sendFileList: addList];

    if ([changeList count] > 0) {
        changeDict = [NSDictionary dictionaryWithObjects:
            [NSArray arrayWithObjects: RenFilesChangedKey, changeList, nil]
                                                 forKeys:
            [NSArray arrayWithObjects: @"type", @"arg", nil]];
        [self sendCommand: changeDict];
    }
}

/*
 * Figure out what type of connection this is, and dispatch appropriately.
 */
- (void)doHandshake: (NSNotification *)aNotification
{
    NSData *data;
    NSDictionary *clientMsg;
    NSFileHandle *remoteSocket;
    NSNotificationCenter *defaultCenter;

    remoteSocket = [aNotification object];
    defaultCenter = [NSNotificationCenter defaultCenter];

    data = [[aNotification userInfo] objectForKey:
        NSFileHandleNotificationDataItem];

    clientMsg = [self processData: data];
    if (clientMsg != nil) {
        NSString *clientType;

        clientType = [clientMsg objectForKey: @"type"];
        if ([clientType isEqualToString: @"browser"]) {
            [defaultCenter removeObserver: self
                                     name: NSFileHandleReadCompletionNotification
                                   object: [self file]];
            [self sendFileList: [[self fileStore] allFileHandles]];

            [defaultCenter addObserver: self
                              selector: @selector(respondToFileChanged:)
                                  name: LiFileChangedNotification
                                object: [self fileStore]];
        } else if ([clientType isEqualToString: @"download"]) {
            LiFileHandle *tmpFile;
            id handle;

            handle = [clientMsg objectForKey: LiFileHandleAttribute];
            tmpFile = [[[LiFileHandle alloc] init] autorelease];
            [tmpFile setFileStore: [self fileStore]];
            [tmpFile setFileID: handle];
            if ([self filePassesFilter: tmpFile]) {
                [defaultCenter removeObserver: self
                                         name: NSFileHandleReadCompletionNotification
                                       object: [self file]];

                [self startCopyOfFileHandle: tmpFile];
            } else {
                [LiLog logAsWarning: @"attempt to access non-shared file: %@.", [tmpFile url]];
                [self shutdown];
                return;
            }
        }
    }

    [remoteSocket readInBackgroundAndNotify];
}

- (void)shutdown
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName: CLIENTMANAGERDEATHNOTIFICATION
                                 object: self
                               userInfo: nil];
}

- (void)sendHostname
{
    NSDictionary *tmpDict;

    tmpDict = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects: RenHostnameKey, [self hostname], nil]
                                          forKeys:
        [NSArray arrayWithObjects: @"type", @"arg", nil]];
    [self sendCommand: tmpDict];
}

- (void)respondToFileChanged: (NSNotification *)aNotification
{
    NSDictionary *fileDict;

    fileDict = [aNotification userInfo];
    if ([fileDict objectForKey: LiFilesAdded] != nil) {
        [self sendFileList: [fileDict objectForKey: LiFilesAdded]];
    }
    if ([fileDict objectForKey: LiFilesChanged]) {
        [self sendChangeList: [fileDict objectForKey: LiFilesChanged]];
    }
    if ([fileDict objectForKey: LiFilesRemoved]) {
        [self sendDeleteList: [fileDict objectForKey: LiFilesRemoved]];
    }
}

- (void)remoteClosed: (NSNotification *)aNotification
{
    [self shutdown];
}
@synthesize theFile;
@synthesize theFileStore;
@synthesize theHostname;
@synthesize theBuffer;
@synthesize theCopyFile;
@end

@implementation ClientManager (Accessors)
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

- (NSFileHandle *)copyFile
{
    return theCopyFile;
}

- (void)setCopyFile: (NSFileHandle *)aFile
{
    [aFile retain];
    [theCopyFile release];
    theCopyFile = aFile;
}

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

- (NSString *)hostname
{
    return theHostname;
}

- (void)setHostname: (NSString *)aHostname
{
    [aHostname retain];
    [theHostname release];
    theHostname = aHostname;
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

@implementation ClientManager (Downloader)
#define XMITBUFFLEN 1400

- (void)readyToWrite: (NSNotification *)aNotification
{
    NSData *fileData;
    NSFileHandle *remoteSocket;

    remoteSocket = [aNotification object];
    if (remoteSocket == nil)
        remoteSocket = [self file];

    fileData = [[self copyFile] readDataOfLength: XMITBUFFLEN];
    if ([fileData length] < XMITBUFFLEN) {
        NSNotificationCenter *defaultCenter;

        defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter removeObserver: self
                                 name: FileHandleWriteComplete
                               object: remoteSocket];
        [defaultCenter addObserver: self
                          selector: @selector(finishedCopying:)
                              name: FileHandleWriteComplete
                            object: remoteSocket];
    }

    [(NSFileHandleExtensions *)remoteSocket writeDataInBackground: fileData];
}

- (void)startCopyOfFileHandle: (LiFileHandle *)aFileHandle
{
    NSNotificationCenter *defaultCenter;
    NSURL *fileURL;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(readyToWrite:)
                          name: FileHandleWriteComplete
                        object: [self file]];

    fileURL = [aFileHandle url];
    if (fileURL != nil && [fileURL isFileURL]) {
        [self setCopyFile:
            [NSFileHandle fileHandleForReadingAtPath: [fileURL path]]];
    }
    [self readyToWrite: nil];
}

- (void)finishedCopying: (NSNotification *)aNotification
{
    NSFileHandle *remoteSocket;
    NSNotificationCenter *defaultCenter;

    remoteSocket = [aNotification object];

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self
                             name: FileHandleWriteComplete
                           object: remoteSocket];
    [defaultCenter removeObserver: self
                             name: NSFileHandleReadCompletionNotification
                           object: remoteSocket];

    [self setCopyFile: nil];
    [self shutdown];
}
@end