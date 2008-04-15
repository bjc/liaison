//
//  ClientManager.h
//  Liaison
//
//  Created by Brian Cully on Sun Feb 16 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface ClientManager : NSObject {
    LiFileStore *theFileStore;
    NSFileHandle *theFile;
    NSString *theHostname;

    NSFileHandle *theCopyFile;

    NSMutableData *theBuffer;
}

- (id)initWithFile: (NSFileHandle *)aFile
      andFileStore: (LiFileStore *)aFileStore;

- (void)startup;
- (void)shutdown;
- (void)sendHostname;
@property (retain,getter=copyFile) NSFileHandle *theCopyFile;
@property (retain,getter=buffer) NSMutableData *theBuffer;
@property (retain,getter=fileStore) LiFileStore *theFileStore;
@property (retain,getter=file) NSFileHandle *theFile;
@property (retain,getter=hostname) NSString *theHostname;
@end

@interface ClientManager (Accessors)
- (NSMutableData *)buffer;
- (void)setBuffer: (NSMutableData *)aBuffer;
- (NSFileHandle *)copyFile;
- (void)setCopyFile: (NSFileHandle *)aFile;
- (NSFileHandle *)file;
- (void)setFile: (NSFileHandle *)aFile;
- (NSString *)hostname;
- (void)setHostname: (NSString *)aHostname;
- (LiFileStore *)fileStore;
- (void)setFileStore: (LiFileStore *)aFileStore;
@end
