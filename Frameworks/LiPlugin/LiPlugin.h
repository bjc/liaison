/*
 *  LiPlugin.h
 *  Liaison
 *
 *  Created by Brian Cully on Tue May 13 2003.
 *  Copyright (c) 2003 Brian Cully. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#import <LiPlugin/LiBrowserColumn.h>
#import <LiPlugin/LiInspectorView.h>
#import <LiPlugin/LiFilterDescription.h>

#import <LiBackend/LiBackend.h>

@protocol LiFileStorePlugin
+ (NSBundle *)bundle;
+ (void)setBundle: (NSBundle *)aBundle;

- (void)initFileStore;
- (LiFileStore *)fileStore;
@end

@protocol LiBrowserPlugin
+ (NSBundle *)bundle;
+ (void)setBundle: (NSBundle *)aBundle;

- (NSArray *)columns;
- (NSDictionary *)filterDescriptions;
@end

@protocol LiInspectorPlugin
+ (NSBundle *)bundle;
+ (void)setBundle: (NSBundle *)aBundle;

- (NSArray *)allInspectorViews;
- (NSArray *)inspectorViewsForFile: (LiFileHandle *)aFile;
- (void)setFile: (LiFileHandle *)aFile;
@end