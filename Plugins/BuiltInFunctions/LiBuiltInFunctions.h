//
//  LiBuiltInFunctions.h
//  Liaison
//
//  Created by Brian Cully on Tue May 13 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "BDAlias.h"

#define LiAliasDataAttribute @"LiAliasAttribute"

@class InspectorViewController;

@interface LiBuiltInFunctions : NSObject
<LiBrowserPlugin, LiInspectorPlugin, LiFileStorePlugin, LiFileStoreDelegate>
{
    IBOutlet InspectorViewController *theController;
    LiFileStore *theFileStore;

    NSMutableDictionary *theDefaultAttributes;
}
@property (retain) InspectorViewController *theController;
@property (retain,getter=fileStore) LiFileStore *theFileStore;
@property (retain,getter=defaultAttributes) NSMutableDictionary *theDefaultAttributes;
@end

@interface LiBuiltInFunctions (Accessors)
- (void)setFileStore: (LiFileStore *)aFileStore;
- (InspectorViewController *)viewController;
- (NSMutableDictionary *)defaultAttributes;
- (void)setDefaultAttributes: (NSMutableDictionary *)someAttributes;
@end

@interface LiFileHandle (LiBuiltInFunctions)
- (NSImage *)icon;
- (NSString *)path;
- (NSString *)directory;
- (BDAlias *)alias;
- (void)setAlias: (BDAlias *)anAlias;
@end