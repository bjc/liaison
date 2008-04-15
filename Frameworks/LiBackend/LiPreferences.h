//
//  Preferences.h
//  Liaison
//
//  Created by Brian Cully on Fri Feb 21 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface Preferences : NSObject
{
    NSUserDefaults *theDefaults;
}

+ (Preferences *)sharedPreferences;

- (NSString *)downloadDirectory;
- (void)setDownloadDirectory: (NSString *)aPath;
- (NSString *)groupPath;
- (void)setGroupPath: (NSString *)aPath;
- (NSString *)libraryPath;
- (void)setLibraryPath: (NSString *)aPath;
- (NSString *)hostname;
- (void)setHostname: (NSString *)aHostname;
- (BOOL)networkEnabled;
- (void)setNetworkEnabled: (BOOL)isEnabled;
- (BOOL)useRendezvousGroup;
- (void)setUseRendezvousGroup: (BOOL)useGroup;
- (NSDictionary *)fileListPrefs;
- (void)setFileListPrefs: (NSDictionary *)listPrefs;
@property (retain) NSUserDefaults *theDefaults;
@end
