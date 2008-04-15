//
//  LiFileHandle.m
//  Liaison
//
//  Created by Brian Cully on Sat May 24 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiFileHandle.h"

@implementation LiFileHandle (Copying)
- (id)copyWithZone: (NSZone *)aZone
{
    LiFileHandle *tmpHandle;
    
    tmpHandle = [[LiFileHandle allocWithZone: aZone] init];
    [tmpHandle setStoreID: [self storeID]];
    [tmpHandle setFileID: [self fileID]];

    return tmpHandle;
}

- (unsigned)hash
{
    unsigned long storeID, fileID;

    storeID = [[self storeID] unsignedLongValue];
    fileID = [[self fileID] unsignedLongValue];

    // Fold the store ID down to 4 bits.
    storeID = (storeID & 0xf) ^ (storeID >> 4 & 0xf) ^
        (storeID >> 8 & 0xf) ^ (storeID >> 12 & 0xf) ^
        (storeID >> 16 & 0xf) ^ (storeID >> 20 & 0xf) ^
        (storeID >> 24 & 0xf) ^ (storeID >> 28 & 0xf);

    // Fold the handle to 12 bits.
    fileID = (fileID & 0xfff) ^ (fileID >> 12 & 0xfff) ^
        (fileID >> 24 & 0xfff);

    return (storeID << 12) | fileID;
}

- (BOOL)isEqual: (id)anObject
{
    if ([anObject isKindOfClass: [self class]]) {
        IMP compareMethod;
        id myID;

        myID = [self fileID];
        compareMethod = [myID methodForSelector: @selector(compare:)];
        if (compareMethod != nil &&
            compareMethod(myID, @selector(compare:), [anObject fileID]) == 0) {
            myID = [self storeID];
            compareMethod = [myID methodForSelector: @selector(compare:)];
            if (compareMethod != nil &&
                compareMethod(myID, @selector(compare:), [anObject storeID]) == 0)
                return YES;
        }
    }

    return NO;
}
@end

@implementation LiFileHandle
+ (LiFileHandle *)fileHandleWithID: (id)aFileID
                           storeID: (id)aStoreID
{
    LiFileHandle *tmpHandle;

    tmpHandle = [[[LiFileHandle alloc] init] autorelease];
    [tmpHandle setFileID: aFileID];
    [tmpHandle setStoreID: aStoreID];

    return tmpHandle;
}

- (id)init
{
    return [super init];
}

- (void)dealloc
{
    [self setStoreID: nil];
    [self setFileID: nil];
    
    [super dealloc];
}

- (id)initWithCoder: (NSCoder *)aCoder
{
    id storeID, fileID;
    
    self = [self init];

    if ([aCoder allowsKeyedCoding]) {
        storeID = [aCoder decodeObjectForKey: @"LiStoreID"];
        fileID = [aCoder decodeObjectForKey: @"LiFileID"];
    } else {
        storeID = [aCoder decodeObject];
        fileID = [aCoder decodeObject];
    }
    [self setStoreID: storeID];
    [self setFileID: fileID];
    
    return self;
}

- (void)encodeWithCoder: (NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject: [self storeID]
                      forKey: @"LiStoreID"];
        [aCoder encodeObject: [self fileID]
                      forKey: @"LiFileID"];
    } else {
        [aCoder encodeObject: [self storeID]];
        [aCoder encodeObject: [self fileID]];
    }
}

- (BOOL)shouldUpdate
{
    return NO;
}

- (id)valueForAttribute: (NSString *)anAttribute
{
    NSDictionary *attrDict;

    attrDict = [self dictionary];
    return [attrDict objectForKey: anAttribute];
}

- (void)setValue: (id)aValue forAttribute: (NSString *)anAttribute
{
    if (aValue != nil)
        [self setValues: [NSArray arrayWithObject: aValue]
          forAttributes: [NSArray arrayWithObject: anAttribute]];
}

- (NSArray *)valuesForAttributes: (NSArray *)someAttributes
{
    NSDictionary *attributes;
    NSMutableArray *someValues;
    NSString *attribute;

    attributes = [self dictionary];
    someValues = [NSMutableArray array];
    for (attribute in someAttributes) {
        [someValues addObject: [attributes objectForKey: attribute]];
    }

    return someValues;
}

- (void)setValues: (NSArray *)someValues forAttributes: (NSArray *)someAttributes
{
    NSDictionary *newAttributes;
    
    newAttributes = [NSDictionary dictionaryWithObjects: someValues
                                                forKeys: someAttributes];
    [[self fileStore] updateFileHandle: self withAttributes: newAttributes];
}
@synthesize theStoreID;
@synthesize theFileID;
@end

@implementation LiFileHandle (Accessors)
- (id)storeID
{
    return theStoreID;
}

- (void)setStoreID: (id)aStoreID
{
    [aStoreID retain];
    [theStoreID release];
    theStoreID = aStoreID;
}

- (id)fileID
{
    return theFileID;
}

- (void)setFileID: (id)aFileID
{
    [aFileID retain];
    [theFileID release];
    theFileID = aFileID;
}
@end

@implementation LiFileHandle (CommonAccessors)
- (LiFileStore *)fileStore
{
    return [LiFileStore fileStoreWithID: [self storeID]];
}

- (void)setFileStore: (LiFileStore *)aFileStore
{
    [self setStoreID: [aFileStore storeID]];
}

- (BOOL)isEditable
{
    return [[self valueForAttribute: LiIsEditableAttribute] boolValue];
}

- (void)setIsEditable: (BOOL)editable
{
    [self setValue: [NSNumber numberWithBool: editable]
      forAttribute: LiIsEditableAttribute];
}

- (NSString *)filename
{
    return [self valueForAttribute: LiFilenameAttribute];
}

- (void)setFilename: (NSString *)aFilename
{
    [self setValue: aFilename forAttribute: LiFilenameAttribute];
}

- (NSString *)type
{
    return [self valueForAttribute: LiTypeAttribute];
}

- (void)setType: (NSString *)aType
{
    [self setValue: aType forAttribute: LiTypeAttribute];
}

- (NSNumber *)hfsCreator
{
    return [self valueForAttribute: LiHFSCreatorAttribute];
}

- (void)setHFSCreator: (NSNumber *)aTypeCode
{
    [self setValue: aTypeCode forAttribute: LiHFSCreatorAttribute];
}

- (NSNumber *)hfsType
{
    return [self valueForAttribute: LiHFSTypeAttribute];
}

- (void)setHFSType: (NSNumber *)aTypeCode
{
    [self setValue: aTypeCode forAttribute: LiHFSTypeAttribute];
}

- (NSString *)application
{
    return [self valueForAttribute: LiApplicationAttribute];
}

- (void)setApplication: (NSString *)pathToApp
{
    [self setValue: pathToApp forAttribute: LiApplicationAttribute];
}

- (NSDate *)lastModifiedTime
{
    return [self valueForAttribute: LiLastModifiedDateAttribute];
}

- (void)setLastModifiedTime: (NSDate *)aTime
{
    [self setValue: aTime forAttribute: LiLastModifiedDateAttribute];
}

- (NSDate *)creationTime
{
    return [self valueForAttribute: LiCreationDateAttribute];
}

- (void)setCreationTime: (NSDate *)aTime
{
    [self setValue: aTime forAttribute: LiCreationDateAttribute];
}

- (NSNumber *)fileSize
{
    return [self valueForAttribute: LiFileSizeAttribute];
}

- (NSMutableArray *)groups
{
    return [self valueForAttribute: LiGroupsAttribute];
}

- (void)addToGroup: (NSString *)aGroup
{
    NSMutableArray *myGroups, *newGroups;

    myGroups = [self groups];
    if (myGroups != nil) {
        if ([myGroups containsObject: aGroup]) {
            return;
        }
        newGroups = [NSMutableArray arrayWithArray: myGroups];
    } else
        newGroups = [NSMutableArray array];
    [newGroups addObject: aGroup];
    [self setValue: newGroups forAttribute: LiGroupsAttribute];
}

- (BOOL)isMemberOfGroup: (NSString *)aGroup
{
    return [[self groups] containsObject: aGroup];
}

- (void)removeFromGroup: (NSString *)aGroup
{
    NSMutableArray *myGroups, *newGroups;

    myGroups = [self groups];
    if (myGroups != nil) {
        newGroups = [NSMutableArray arrayWithArray: myGroups];
        [newGroups removeObject: aGroup];
        [self setValue: newGroups forAttribute: LiGroupsAttribute];
    }
}

- (void)renameGroup: (NSString *)oldName toGroup: (NSString *)newName
{
    NSMutableArray *myGroups, *newGroups;

    myGroups = [self groups];
    if (myGroups != nil) {
        newGroups = [NSMutableArray arrayWithArray: myGroups];
        [newGroups removeObject: oldName];
        [newGroups addObject: newName];
        [self setValue: newGroups forAttribute: LiGroupsAttribute];
    }
}

- (BOOL)matchesFilter: (LiFilter *)aFilter
{
    return [[self fileStore] attributes: [self dictionary] matchFilter: aFilter];
}
@end

@implementation LiFileHandle (CommonUtilities)
- (NSString *)description
{
    return [[self dictionary] description];
}

- (NSDictionary *)dictionary
{
    return [[self fileStore] attributesForFileID: [self fileID]];
}

- (void)update
{
    [[[self fileStore] delegate] updateFileHandle: self];
}

- (void)open
{
    [[[self fileStore] delegate] openFileHandle: self];
}

- (NSURL *)url
{
    return [[[self fileStore] delegate] urlForFileHandle: self];
}
@end

@implementation LiFileHandle (Scripting)
- (NSScriptObjectSpecifier *)objectSpecifier
{
    NSScriptClassDescription *containerDescription;
    NSScriptObjectSpecifier *containerRef;
    unsigned index;

    [LiLog logAsDebug: @"[LiFileHandle objectSpecifier]"];
    
    index = [[[self fileStore] allFileHandles] indexOfObject: self];
    if (index != NSNotFound) {
        [LiLog logAsDebug: @"index: %@", [NSNumber numberWithUnsignedInt: index]];
        containerRef = [LiFileStore objectSpecifier];
        containerDescription = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[LiFileStore class]];

        return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerDescription containerSpecifier:containerRef key:@"allFileHandles" index:index] autorelease];
    } else
        return nil;
}

- (NSString *)urlString
{
    return [[self url] absoluteString];
}
@end

@implementation LiFileStore (LiFileHandleMethods)
- (LiFileHandle *)addFileWithAttributes: (NSDictionary *)someAttributes
{
    LiFileHandle *tmpHandle;
    id fileID;
    
    tmpHandle = nil;
    fileID = [self fileIDWithAttributes: someAttributes];
    if (fileID != nil)
        tmpHandle = [LiFileHandle fileHandleWithID: fileID storeID: [self storeID]];
    return tmpHandle;
}

- (NSDictionary *)attributesForFileHandle: (LiFileHandle *)aFileHandle
{
    return [self attributesForFileID: [aFileHandle fileID]];
}

- (void)updateFileHandle: (LiFileHandle *)aFileHandle
          withAttributes: (NSDictionary *)someAttributes
{
    [self updateFileID: [aFileHandle fileID] withAttributes: someAttributes];
}

- (void)removeFileHandle: (LiFileHandle *)aFileHandle
{
    [self removeFileID: [aFileHandle fileID]];
}

- (NSArray *)allFileHandles
{
    NSEnumerator *idEnum;
    NSMutableArray *fileHandles;
    id fileID;
    
    fileHandles = [NSMutableArray array];
    idEnum = [[self allFileIDs] objectEnumerator];
    while ((fileID = [idEnum nextObject]) != nil) {
        LiFileHandle *tmpHandle;
        
        tmpHandle = [[LiFileHandle alloc] init];
        [tmpHandle setStoreID: [self storeID]];
        [tmpHandle setFileID: fileID];
        [fileHandles addObject: tmpHandle];
        [tmpHandle release];
    }
    
    return fileHandles;
}

- (NSArray *)filesMatchingFilter: (LiFilter *)aFilter
{
    NSArray *fileIDs;
    NSMutableArray *fileHandles;
    
    fileHandles = nil;
    fileIDs = [self fileIDsMatchingFilter: aFilter];
    if ([fileIDs count] > 0) {
        id fileID;
        
        fileHandles = [NSMutableArray array];
        for (fileID in fileIDs) {
            LiFileHandle *tmpHandle;

            tmpHandle = [[LiFileHandle alloc] init];
            [tmpHandle setStoreID: [self storeID]];
            [tmpHandle setFileID: fileID];
            [fileHandles addObject: tmpHandle];
            [tmpHandle release];
        }
    }
    return fileHandles;
}
@end