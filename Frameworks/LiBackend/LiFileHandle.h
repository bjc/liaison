//
//  LiFileHandle.h
//  Liaison
//
//  Created by Brian Cully on Sat May 24 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiFileHandle : NSObject <NSCoding>
{
    id theStoreID;
    id theFileID;
}
+ (LiFileHandle *)fileHandleWithID: (id)aFileID
                           storeID: (id)aStoreID;

// For the file validator methods.
- (BOOL)shouldUpdate;

- (id)valueForAttribute: (NSString *)anAttribute;
- (void)setValue: (id)aValue forAttribute: (NSString *)anAttribute;
- (NSArray *)valuesForAttributes: (NSArray *)someAttributes;
- (void)setValues: (NSArray *)someValues forAttributes: (NSArray *)someAttributes;
@property (retain,getter=fileID) id theFileID;
@property (retain,getter=storeID) id theStoreID;
@end

@interface LiFileHandle (Accessors)
- (id)storeID;
- (void)setStoreID: (id)aStoreID;
- (id)fileID;
- (void)setFileID: (id)aFileID;
@end

// These are common access methods - actually nothing more than convenience
// methods that are nothing more than wrappers to valueForAttribute: and
// setValue:forAttribute:
// It is recommended that plugins use the same method for attribute access.
@interface LiFileHandle (CommonAccessors)
- (LiFileStore *)fileStore;
- (void)setFileStore: (LiFileStore *)aFileStore;
- (BOOL)isEditable;
- (void)setIsEditable: (BOOL)editable;
- (NSString *)filename;
- (void)setFilename: (NSString *)aFilename;
- (NSString *)type;
- (void)setType: (NSString *)aType;
- (NSNumber *)hfsCreator;
- (void)setHFSCreator: (NSNumber *)aTypeCode;
- (NSNumber *)hfsType;
- (void)setHFSType: (NSNumber *)aTypeCode;
- (NSString *)application;
- (void)setApplication: (NSString *)pathToApp;
- (NSDate *)lastModifiedTime;
- (void)setLastModifiedTime: (NSDate *)aTime;
- (NSDate *)creationTime;
- (void)setCreationTime: (NSDate *)aTime;
- (NSNumber *)fileSize;

- (NSMutableArray *)groups;
- (void)addToGroup: (NSString *)aGroup;
- (BOOL)isMemberOfGroup: (NSString *)aGroup;
- (void)removeFromGroup: (NSString *)aGroup;
- (void)renameGroup: (NSString *)oldName toGroup: (NSString *)newName;
- (BOOL)matchesFilter: (LiFilter *)aFilter;
@end

@interface LiFileHandle (CommonUtilities)
- (NSString *)description;
- (NSDictionary *)dictionary;
- (void)update;
- (void)open;
- (NSURL *)url;
@end

@interface LiFileHandle (Scripting)
- (NSScriptObjectSpecifier *)objectSpecifier;

- (NSString *)urlString;
@end

@interface LiFileStore (LiFileHandleMethods)
// Add a file to the library with the results of
// [LiFileStore fileSystemAttributesForPath:].
- (LiFileHandle *)addFileWithAttributes: (NSDictionary *)someAttributes;

// To get a file's attributes.
- (NSDictionary *)attributesForFileHandle: (LiFileHandle *)aFileHandle;

// Set the attributes to be updated in the dictionary.
- (void)updateFileHandle: (LiFileHandle *)aFileHandle
          withAttributes: (NSDictionary *)someAttributes;

// Remove file from the library.
- (void)removeFileHandle: (LiFileHandle *)aFileHandle;

// Returns all the LiFileHandles in the store.
- (NSArray *)allFileHandles;

// Returns a list of LiFileHandle objects for attributes
// that match the dictionary.
- (NSArray *)filesMatchingFilter: (LiFilter *)aFilter;
@end