//
//  PluginManager.h
//  Liaison
//
//  Created by Brian Cully on Thu May 15 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface PluginManager : NSObject
{
    NSMutableArray *theFileStorePlugins;
    NSMutableArray *theBrowserPlugins;
    NSMutableArray *theInspectorPlugins;
}

+ (PluginManager *)defaultManager;
- (void)scanForPlugins;
@property (retain) NSMutableArray *theFileStorePlugins;
@property (retain) NSMutableArray *theInspectorPlugins;
@property (retain) NSMutableArray *theBrowserPlugins;
@end

@interface PluginManager (Accessors)
- (NSArray *)fileStorePlugins;
- (NSArray *)browserPlugins;
- (NSArray *)inspectorPlugins;
@end
