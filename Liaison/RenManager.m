//
//  RenManager.m
//  Liaison
//
//  Created by Brian Cully on Sun Feb 16 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//
#import "RenIPC.h"
#import "RenManager.h"

#import "ClientManager.h"
#import "ServerManager.h"

#import <netinet/in.h>
#import <sys/socket.h>

@implementation RenManager (NetServiceDelegate)
- (void)serverManagerDied: (NSNotification *)aNotification
{
    ServerManager *deadServer;
    
    [LiLog logAsDebug: @"server manager died."];
    deadServer = [aNotification object];
    [theServersByName removeObjectForKey: [[deadServer service] name]];
}

- (void)clientManagerDied: (NSNotification *)aNotification
{
    ClientManager *client;
    
    client = [aNotification object];
    if (client != nil) {
        [LiLog logAsDebug: @"removing client for %@!", [client file]];
        [theClients removeObjectForKey: [client file]];
        [LiLog logAsDebug: @"removed client!"];
    }
}

- (void)acceptConnection: (NSNotification *)aNotification
{
    ClientManager *client;
    NSDictionary *userInfo;
    NSFileHandle *socket;
    NSNotificationCenter *defaultCenter;
    
    userInfo = [aNotification userInfo];
    socket = [userInfo objectForKey:
        NSFileHandleNotificationFileHandleItem];

    client = [[ClientManager alloc] initWithFile: socket
                                    andFileStore: [self fileStore]];
    //[socket release];

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(clientManagerDied:)
                          name: CLIENTMANAGERDEATHNOTIFICATION
                        object: client];

    [theClients setObject: client forKey: [client file]];
    [client startup];
    [client release];

    [[self listenSocket] acceptConnectionInBackgroundAndNotify];
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    theShareIsEnabled = YES;
    [self setService: sender];
}

- (void)netServiceDidStop: (NSNetService *)sender
{
    theShareIsEnabled = NO;
    [self setService: nil];
}

- (void)netServiceBrowser: (NSNetServiceBrowser *)aNetServiceBrowser
           didFindService: (NSNetService *)aNetService
               moreComing: (BOOL)moreComing
{
    [aNetService setDelegate: self];
    [aNetService resolve];
}

- (void)netServiceBrowserDidStopSearch: (NSNetServiceBrowser *)browser
{
    [LiLog logAsDebug: @"stopping search."];
}

- (void)netServiceWillResolve: (NSNetService *)aNetService
{
}

- (void)netServiceDidResolveAddress: (NSNetService *)aNetService
{
    ServerManager *server;

    if ([theServersByName objectForKey: [aNetService name]] == nil) {
        server = [[ServerManager alloc] initWithNetService: aNetService];
        if (server != nil) {
            [theServersByName setObject: server forKey: [aNetService name]];
            [server startup];
        }
    }
}

// XXX - should set group name to IP address and proceed.
- (void)netService: (NSNetService *)aNetService
     didNotResolve: (NSDictionary *)someErrors
{
    [LiLog logAsDebug: @"XXX: Couldn't resolve address for %@.", [aNetService name]];
}

- (void)netServiceBrowser: (NSNetServiceBrowser *)aNetServiceBrowser
         didRemoveService: (NSNetService *)aNetService
               moreComing: (BOOL)moreComing
{
    ServerManager *removedServer;
    
    [LiLog logAsDebug: @"removing service: %@", [aNetService name]];
    removedServer = [theServersByName objectForKey: [aNetService name]];
    [LiLog logAsDebug: @"\tremoved file store: %@", [[removedServer fileStore] storeID]];
    [removedServer shutdown];
}
@end

@implementation RenManager
static RenManager *sharedManager = nil;

+ (RenManager *)sharedManager
{
    if (sharedManager == nil)
        sharedManager = [[RenManager alloc] init];
    return sharedManager;
}

- (id)init
{
    NSNotificationCenter *defaultCenter;
    
    self = [super init];

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(serverManagerDied:)
                          name: SERVERMANAGERDEATHNOTIFICATION
                        object: nil];
    
    [self setFileStore: nil];

    theServersByName = [[NSMutableDictionary alloc] init];
    theClients = [[NSMutableDictionary alloc] init];

    [self setListenSocket: nil];
    [self setListenPort: nil];
    [self setService: nil];
    [self setBrowser: nil];

    theShareIsEnabled = NO;
        
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];
    
    [self setFileStore: nil];

    [theServersByName release];
    [theClients release];

    [self setListenSocket: nil];
    [self setListenPort: nil];
    [self setService: nil];
    [self setBrowser: nil];
    
    [super dealloc];
}

- (void)startup
{
    NSNetServiceBrowser *browser;
    
    if ([[Preferences sharedPreferences] networkEnabled])
        [self startSharing];

    browser = [[NSNetServiceBrowser alloc] init];
    [browser autorelease];
    [browser setDelegate: self];
    [browser searchForServicesOfType: LiRendezvousPortName
                            inDomain: @""];
    [self setBrowser: browser];
}

- (void)startSharing
{
    NSFileHandle *listenSocket;
    NSNetService *service;
    NSNotificationCenter *defaultCenter;
    NSSocketPort *listenPort;
    NSString *hostname;
    struct sockaddr *addr;
    int port;

    if (theShareIsEnabled)
        return;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(acceptConnection:)
                          name: NSFileHandleConnectionAcceptedNotification
                        object: nil];

    listenPort = [[NSSocketPort alloc] init];
    [listenPort autorelease];
    listen([listenPort socket], 10);
    [self setListenPort: listenPort];
    
    listenSocket = [[NSFileHandle alloc] initWithFileDescriptor: [listenPort socket]
                                                 closeOnDealloc: YES];
    [listenSocket autorelease];
    [listenSocket acceptConnectionInBackgroundAndNotify];
    [self setListenSocket: listenSocket];

    hostname = [[Preferences sharedPreferences] hostname];
    addr = (struct sockaddr *)[[listenPort address] bytes];
    if (addr->sa_family == AF_INET6)
        port = ((struct sockaddr_in6 *)addr)->sin6_port;
    else
        port = ((struct sockaddr_in *)addr)->sin_port;

    service = [[NSNetService alloc] initWithDomain: @""
                                              type: LiRendezvousPortName
                                              name: hostname
                                              port: port];
    [service autorelease];
    [service setDelegate: self];
    [service publish];
}

- (void)stopSharing
{
    if (theShareIsEnabled) {
        NSNotificationCenter *defaultCenter;
        NSEnumerator *clientEnum;
        id clientKey;

        [[self service] stop];
        [self setListenSocket: nil];

        defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter removeObserver: self
                                 name: NSFileHandleConnectionAcceptedNotification
                               object: nil];

        clientEnum = [theClients keyEnumerator];
        while ((clientKey = [clientEnum nextObject]) != nil) {
            ClientManager *client;

            [LiLog logAsDebug: @"shutting down client"];
            client = [theClients objectForKey: clientKey];
            [client shutdown];
        }
        [LiLog logAsDebug: @"sharing stopped."];
    }
}

- (void)updateHostname
{
    if (theShareIsEnabled) {
        ClientManager *client;
        NSEnumerator *clientEnum;

        clientEnum = [theClients objectEnumerator];
        while ((client = [clientEnum nextObject]) != nil) {
            [client setHostname: [[Preferences sharedPreferences] hostname]];
            [client sendHostname];
        }
    }
}
@synthesize theBrowser;
@synthesize theServersByName;
@synthesize theService;
@synthesize theListenSocket;
@synthesize theFileStore;
@synthesize theShareIsEnabled;
@synthesize theClients;
@synthesize theListenPort;
@end

@implementation RenManager (Accessors)
- (NSNetServiceBrowser *)browser
{
    return theBrowser;
}

- (void)setBrowser: (NSNetServiceBrowser *)aBrowser
{
    [aBrowser retain];
    [theBrowser release];
    theBrowser = aBrowser;
}

- (NSSocketPort *)listenPort
{
    return theListenPort;
}

- (void)setListenPort: (NSSocketPort *)aPort
{
    [aPort retain];
    [theListenPort release];
    theListenPort = aPort;
}

- (NSFileHandle *)listenSocket
{
    return theListenSocket;
}

- (void)setListenSocket: (NSFileHandle *)aSocket
{
    [aSocket retain];
    [theListenSocket release];
    theListenSocket = aSocket;
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