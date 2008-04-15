//
//  LiFileStore.h
//  Liaison
//
//  Created by Brian Cully on Sat May 24 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

// Notification names.
//
// When the file store list changes.
#define LiFileStoresChangedNotification @"LiFileStoresChangedNotification"
// When a file gets changed.
#define LiFileChangedNotification @"LiFileChangedNotification"

// Keys in the userInfo for LiFileStoresChangedNotification
#define LiFileStoreAdded @"LiFileStoreAdded"
#define LiFileStoreRemoved @"LiFileStoreRemoved"

// Keys in the userInfo for LiFileChangedNotification.
#define LiFilesAdded @"LiFilesAdded"
#define LiFilesChanged @"LiFilesChanged"
#define LiFilesRemoved @"LiFilesRemoved"

// For LiFilesChanged and LiFilesRemoved.
#define LiFileOldAttributes @"LiFilesOldAttributes"

// The keys we supply for every file.
#define LiFileHandleAttribute @"LiFileHandleAttribute"
#define LiDirectoryAttribute @"LiDirectoryAttribute"
#define LiFilenameAttribute @"LiFilenameAttribute"
#define LiTypeAttribute @"LiTypeAttribute"
#define LiLastModifiedDateAttribute @"LiLastModifiedDateAttribute"
#define LiCreationDateAttribute @"LiCreationDateAttribute"
#define LiFileSizeAttribute @"LiFileSizeAttribute"
#define LiGroupsAttribute @"LiGroupsAttribute"
#define LiHFSCreatorAttribute @"LiHFSCreatorAttribute"
#define LiHFSTypeAttribute @"LiHFSTypeAttribute"
#define LiApplicationAttribute @"LiApplicationAttribute"
#define LiIsEditableAttribute @"LiIsEditableAttribute"

@class LiFileHandle;
@class LiFileStore;
@class LiFilter;

@protocol LiFileStoreDelegate <NSObject>
// Sync the file store database to permanent storage.
- (BOOL)synchronizeFileStore;

    // Sync the file handle to disk.
- (void)synchronizeFileHandle: (LiFileHandle *)aFileHandle
            withNewAttributes: (NSMutableDictionary *)someAttributes;

    // Update a file handle from permanent storage.
- (BOOL)shouldUpdateFileHandle: (LiFileHandle *)aFileHandle;
- (void)updateFileHandle: (LiFileHandle *)aFileHandle;

// Open a file handle. Since a file must be on local storage to
// open it, if the file doesn't exist there, delegates must first
// create the file before opening it.
- (void)openFileHandle: (LiFileHandle *)aFileHandle;

// Attempt to add a file, specified by a URL, to the library.
// Returns a non-nil LiFileHandle that matches the newly added file
// on success, nil on failure.
- (LiFileHandle *)addURL: (NSURL *)anURL
             toFileStore: (LiFileStore *)aFileStore;

// Return a standard URL for a file. This can be anything you want,
// but it should always point to the file in some way.
- (NSURL *)urlForFileHandle: (LiFileHandle *)aFileHandle;

// Used to fill in default values for a particular attribute.
// For instance, you can return a set of groups for LiGroupsAttribute.
- (NSArray *)defaultValuesForAttribute: (NSString *)anAttribute;

// For messing with the default attributes for a plugin.
- (BOOL)addDefaultAttribute: (NSDictionary *)anAttribute toFileStore: (LiFileStore *)aFileStore;
- (BOOL)changeDefaultValueForAttribute: (NSDictionary *)anAttribute toValue: (id)aValue inFileStore: (LiFileStore *)aFileStore;
- (BOOL)removeDefaultAttribute: (NSDictionary *)anAttribute fromFileStore: (LiFileStore *)aFileStore;
@end

@interface LiFileStore : NSObject <NSCopying, NSCoding>
{
    id theStoreID;
    id <LiFileStoreDelegate>theDelegate;

    BOOL theStoreIsEditable;
    
    NSImage *theIcon;
    NSString *theName;
    
    NSMutableDictionary *theFiles;
    NSMutableDictionary *theIndexes;

    NSMutableSet *theAddedFiles, *theChangedFiles, *theRemovedFiles;

    unsigned long nextHandle;
}
// Look up stores via ID.
+ (NSArray *)allFileStores;
+ (NSEnumerator *)fileStoreEnumerator;
+ (LiFileStore *)fileStoreWithID: (id)aStoreID;
+ (void)removeStoreWithID: (id)aStoreID;

// Create an auto-released file store.
+ (LiFileStore *)fileStoreWithName: (NSString *)aName;
- (LiFileStore *)initWithName: (NSString *)aName;

// Use the following methods to control how to manage store indexes.
- (void)addIndexForAttribute: (NSString *)anAttribute;
- (NSMutableDictionary *)indexForAttribute: (NSString *)anAttribute;
- (void)removeIndexForAttribute: (NSString *)anAttribute;

- (id)fileIDWithAttributes: (NSDictionary *)someAttributes;
- (void)updateFileID: (id)aFileID
      withAttributes: (NSDictionary *)someAttributes;
- (void)removeFileID: (id)aFileID;

- (NSDictionary *)attributesForFileID: (id)aFileID;

- (NSArray *)allFileIDs;

- (NSArray *)fileIDsMatchingFilter: (LiFilter *)aFilter;

// Test attribute dictionaries against a filter.
- (BOOL)attributes: (NSDictionary *)someAttributes
       matchFilter: (LiFilter *)aFilter;

// Return all the values in the library for an attribute.
- (NSArray *)allValuesForAttribute: (NSString *)anAttribute;
@property unsigned long nextHandle;
@property (retain,getter=name) NSString *theName;
@property (retain,getter=icon) NSImage *theIcon;
@property (retain) NSMutableDictionary *theIndexes;
@property (retain,getter=storeID) id theStoreID;
@property (retain,getter=delegate) id <LiFileStoreDelegate>theDelegate;
@property (getter=isEditable,setter=setEditable:) BOOL theStoreIsEditable;
@property (retain) NSMutableDictionary *theFiles;
@end

@interface LiFileStore (CommonAccessors)
- (void)synchronize;
- (LiFileHandle *)addURL: (NSURL *)anURL;
@end

@interface LiFileStore (Accessors)
- (id)storeID;
- (void)setStoreID: (id)anID;
- (id <LiFileStoreDelegate>)delegate;
- (void)setDelegate: (id <LiFileStoreDelegate>)aDelegate;
- (BOOL)isEditable;
- (void)setEditable: (BOOL)editable;
- (NSString *)name;
- (void)setName: (NSString *)aName;
- (NSImage *)icon;
- (void)setIcon: (NSImage *)anIcon;
- (NSMutableSet *)addedFiles;
- (void)setAddedFiles: (NSMutableSet *)aSet;
- (NSMutableSet *)changedFiles;
- (void)setChangedFiles: (NSMutableSet *)aSet;
- (NSMutableSet *)removedFiles;
- (void)setRemovedFiles: (NSMutableSet *)aSet;
@end

@interface LiFileStore (Scripting)
- (NSScriptObjectSpecifier *)objectSpecifier;
@end