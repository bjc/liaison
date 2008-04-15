//
//  Preferences.m
//  Liaison
//
//  Created by Brian Cully on Fri Feb 21 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiPreferences.h"

// Default download directory.
#define DOWNLOADSPATH @"/Desktop"

// Default library datastore paths.
#define LIBRARYPATH @"/Library/Liaison/Liaison Library.xml"
#define GROUPPATH @"/Library/Liaison/Liaison Groups.xml"

// Default hostname.
#define HOSTNAME @"Unknown"

// User default keys.
#define DOWNLOADKEY @"downloadsDirectory"
#define GROUPPATHKEY @"groupPath"
#define HOSTNAMEKEY @"rendezvousHostname"
#define LIBRARYPATHKEY @"libraryPath"
#define NETWORKENABLEDKEY @"networkEnabled"
#define USERENDEZVOUSGROUPKEY @"useRendezvousGroup"
#define FILELISTPREFSKEY @"fileListPrefs"

@implementation Preferences
static Preferences *sharedInstance = nil;

+ (Preferences *)sharedPreferences
{
    if (sharedInstance == nil)
        sharedInstance = [[Preferences alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        theDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)dealloc
{
    [theDefaults synchronize];
  [super dealloc];
}

- (NSString *)defaultDownloadDirectory
{
    return [NSHomeDirectory() stringByAppendingPathComponent:
        DOWNLOADSPATH];
}

- (NSString *)downloadDirectory
{
    NSString *downloadDirectory;

    downloadDirectory = [theDefaults objectForKey: DOWNLOADKEY];
    if (downloadDirectory == nil)
        downloadDirectory = [self defaultDownloadDirectory];
    return downloadDirectory;
}

- (void)setDownloadDirectory: (NSString *)aPath
{
    [theDefaults setObject: aPath forKey: DOWNLOADKEY];
}

- (NSString *)defaultGroupPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent: GROUPPATH];
}

- (NSString *)groupPath
{
    NSString *groupPath;

    groupPath = [theDefaults objectForKey: GROUPPATHKEY];
    if (groupPath == nil)
        groupPath = [self defaultGroupPath];
    return groupPath;
}

- (void)setGroupPath: (NSString *)aPath
{
    [theDefaults setObject: aPath forKey: GROUPPATHKEY];
}

- (NSString *)defaultLibraryPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent: LIBRARYPATH];
}

- (NSString *)libraryPath
{
    NSString *libraryPath;

    libraryPath = [theDefaults objectForKey: LIBRARYPATHKEY];
    if (libraryPath == nil)
        libraryPath = [self defaultLibraryPath];
    return libraryPath;
}

- (void)setLibraryPath: (NSString *)aPath
{
    [theDefaults setObject: aPath forKey: LIBRARYPATHKEY];
}

- (NSString *)defaultHostname
{
    NSArray *hostnames;
    NSString *hostname;

    hostnames = [[NSHost currentHost] names];
    for (hostname in hostnames) {
        NSRange localRange;

        localRange = [hostname rangeOfString: @".local."];
        if (localRange.location != NSNotFound) {
            hostname = [hostname substringToIndex: localRange.location];
            break;
        }
    }
    if (hostname == nil)
        hostname = [hostnames objectAtIndex: 0];

    return hostname;
}

- (NSString *)hostname
{
    NSString *hostname;

    hostname = [theDefaults objectForKey: HOSTNAMEKEY];
    if (hostname == nil)
        hostname = [self defaultHostname];
    return hostname;
}

- (void)setHostname: (NSString *)aHostname
{
    [theDefaults setObject: aHostname forKey: HOSTNAMEKEY];
}

- (BOOL)defaultNetworkEnabled
{
    return YES;
}

- (BOOL)networkEnabled
{
    NSNumber *networkEnabled;

    networkEnabled = [theDefaults objectForKey: NETWORKENABLEDKEY];
    if (networkEnabled == nil)
        return [self defaultNetworkEnabled];
    if ([networkEnabled intValue] == 1)
        return YES;
    else
        return NO;
}
- (void)setNetworkEnabled: (BOOL)isEnabled
{
    if (isEnabled)
        [theDefaults setObject: [NSNumber numberWithInt: 1]
                        forKey: NETWORKENABLEDKEY];
    else
        [theDefaults setObject: [NSNumber numberWithInt: 0]
                        forKey: NETWORKENABLEDKEY];
}

- (BOOL)defaultUseRendezvousGroup
{
    return NO;
}

- (BOOL)useRendezvousGroup
{
    NSNumber *useRendezvousGroup;

    useRendezvousGroup = [theDefaults objectForKey: USERENDEZVOUSGROUPKEY];
    if (useRendezvousGroup == nil)
        return [self defaultUseRendezvousGroup];

    return [useRendezvousGroup boolValue];
}
- (void)setUseRendezvousGroup: (BOOL)useGroup
{
    [theDefaults setObject: [NSNumber numberWithBool: useGroup]
                    forKey: USERENDEZVOUSGROUPKEY];
}

- (NSDictionary *)fileListPrefs
{
    return [theDefaults objectForKey: FILELISTPREFSKEY];
}
- (void)setFileListPrefs: (NSDictionary *)listPrefs
{
    [theDefaults setObject: listPrefs forKey: FILELISTPREFSKEY];
}
@synthesize theDefaults;
@end
