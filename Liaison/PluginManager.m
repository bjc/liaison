//
//  PluginManager.m
//  Liaison
//
//  Created by Brian Cully on Thu May 15 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "PluginManager.h"

@implementation PluginManager
static PluginManager *defaultManager = nil;
+ (PluginManager *)defaultManager
{
    if (defaultManager == nil)
        defaultManager = [[self alloc] init];
    return defaultManager;
}

- (id)init
{
    self = [super init];

    theFileStorePlugins = [[NSMutableArray alloc] init];
    theBrowserPlugins = [[NSMutableArray alloc] init];
    theInspectorPlugins = [[NSMutableArray alloc] init];

    [self scanForPlugins];

    return self;
}

- (void)dealloc
{
    [theFileStorePlugins release];
    [theBrowserPlugins release];
    [theInspectorPlugins release];

    [super dealloc];
}

- (void)activatePluginAtPath: (NSString *)aPath
{
    NSBundle *pluginBundle;

    pluginBundle = [NSBundle bundleWithPath: aPath];
    if (pluginBundle != nil) {
        NSDictionary *pluginDict;
        NSString *classString;

        pluginDict = [pluginBundle infoDictionary];
        classString = [pluginDict objectForKey: @"NSPrincipalClass"];
        if (classString != nil) {
            Class pluginClass;

            pluginClass = NSClassFromString(classString);
            if (pluginClass == nil) {
                id plugin;
                
                pluginClass = [pluginBundle principalClass];
                plugin = [[[pluginClass alloc] init] autorelease];
                if ([pluginClass conformsToProtocol:@protocol(LiFileStorePlugin)]) {
                    [pluginClass setBundle: pluginBundle];
                    [theFileStorePlugins addObject: plugin];
                }
                if ([pluginClass conformsToProtocol:@protocol(LiBrowserPlugin)]) {
                    [pluginClass setBundle: pluginBundle];
                    [theBrowserPlugins addObject: plugin];
                }
                if ([pluginClass conformsToProtocol:@protocol(LiInspectorPlugin)]) {
                    [pluginClass setBundle: pluginBundle];
                    [theInspectorPlugins addObject: plugin];
                }
            }
        }
    }
    return;
}

- (void)scanForPlugins
{
    NSString *appLocation;

    appLocation = [[NSBundle mainBundle] builtInPlugInsPath];
    if (appLocation) {
        NSEnumerator *pluginEnum;
        NSString *pluginPath;

        pluginEnum = [[NSBundle pathsForResourcesOfType: @"liaisonplugin"
                                            inDirectory: appLocation] objectEnumerator];
        while ((pluginPath = [pluginEnum nextObject]) != nil) {
            [self activatePluginAtPath: pluginPath];
        }
    }
}
@synthesize theBrowserPlugins;
@synthesize theFileStorePlugins;
@synthesize theInspectorPlugins;
@end

@implementation PluginManager (Accessors)
- (NSArray *)fileStorePlugins
{
    return theFileStorePlugins;
}

- (NSArray *)browserPlugins
{
    return theBrowserPlugins;
}

- (NSArray *)inspectorPlugins
{
    return theInspectorPlugins;
}
@end
