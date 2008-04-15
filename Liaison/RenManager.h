//
//  RenManager.h
//  Liaison
//
//  Created by Brian Cully on Sun Feb 16 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface RenManager : NSObject {
    NSSocketPort *theListenPort;
    NSFileHandle *theListenSocket;
    NSNetService *theService;
    NSNetServiceBrowser *theBrowser;
    NSMutableDictionary *theServersByName;
    NSMutableDictionary *theClients;

    LiFileStore *theFileStore;

    BOOL theShareIsEnabled;
}
+ (RenManager *)sharedManager;

- (void)startup;
- (void)startSharing;
- (void)stopSharing;
- (void)updateHostname;
@property (retain,getter=listenSocket) NSFileHandle *theListenSocket;
@property (retain,getter=service) NSNetService *theService;
@property (retain) NSMutableDictionary *theServersByName;
@property (retain,getter=browser) NSNetServiceBrowser *theBrowser;
@property (retain) NSMutableDictionary *theClients;
@property BOOL theShareIsEnabled;
@property (retain,getter=fileStore) LiFileStore *theFileStore;
@property (retain,getter=listenPort) NSSocketPort *theListenPort;
@end

@interface RenManager (Accessors)
- (NSNetServiceBrowser *)browser;
- (void)setBrowser: (NSNetServiceBrowser *)aBrowser;
- (LiFileStore *)fileStore;
- (void)setFileStore: (LiFileStore *)aFileStore;
- (NSSocketPort *)listenPort;
- (void)setListenPort: (NSSocketPort *)aPort;
- (NSFileHandle *)listenSocket;
- (void)setListenSocket: (NSFileHandle *)aSocket;
- (NSNetService *)service;
- (void)setService: (NSNetService *)aService;
@end