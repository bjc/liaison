//
//  ServerManager.h
//  Liaison
//
//  Created by Brian Cully on Sun Feb 16 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@class DownloadStatusView;

@interface ServerManager : NSObject
{
    NSFileHandle *theFile;
    NSNetService *theService;
    NSMutableData *theBuffer;

    LiFileStore *theFileStore;
}
- (id)initWithNetService: (NSNetService *)aService;

- (void)startup;
- (void)shutdown;
@property (retain,getter=service) NSNetService *theService;
@property (retain,getter=buffer) NSMutableData *theBuffer;
@property (retain,getter=fileStore) LiFileStore *theFileStore;
@property (retain,getter=file) NSFileHandle *theFile;
@end

@interface ServerManager (Accessors)
- (NSFileHandle *)file;
- (void)setFile: (NSFileHandle *)aFile;
- (NSNetService *)service;
- (void)setService: (NSNetService *)aService;
- (NSMutableData *)buffer;
- (void)setBuffer: (NSMutableData *)aBuffer;
- (LiFileStore *)fileStore;
- (void)setFileStore: (LiFileStore *)aFileStore;
@end

@interface ServerManager (LiFileStore) <LiFileStoreDelegate>
@end