//
//  LiFileStore.m
//  Liaison
//
//  Created by Brian Cully on Sat May 24 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiFileStore.h"

@interface LiFileStore (Private)
- (unsigned)sendNotifications;
- (void)sendAddNotificationForFileHandle: (LiFileHandle *)aFileHandle;
- (void)sendUpdateNotificationForFileHandle: (LiFileHandle *)aFileHandle
                              oldAttributes: (NSDictionary *)oldAttrs;
- (void)sendRemoveNotificationForFileHandle: (LiFileHandle *)aFileHandle
                              oldAttributes: (NSDictionary *)oldAttrs;
@end

@implementation LiFileStore
static NSMutableDictionary *theFileStores = nil;
static unsigned int theNextID = 0;
+ (NSMutableDictionary *)fileStores
{
    if (theFileStores == nil)
        theFileStores = [[NSMutableDictionary alloc] init];
    return theFileStores;
}

+ (NSArray *)allFileStores
{
    return [[self fileStores] allValues];
}

+ (NSEnumerator *)fileStoreEnumerator
{
    return [[self fileStores] objectEnumerator];
}

+ (LiFileStore *)fileStoreWithID: (id)aStoreID
{
    return [[self fileStores] objectForKey: aStoreID];
}

+ (void)addStore: (LiFileStore *)aFileStore
{
    NSDictionary *userInfo;
    NSNotificationCenter *defaultCenter;
    
    while (([self fileStoreWithID:
        [NSNumber numberWithUnsignedInt: theNextID]]) != nil)
        theNextID++;

    [[self fileStores] setObject: aFileStore forKey:
        [NSNumber numberWithUnsignedInt: theNextID]];
    [aFileStore setStoreID: [NSNumber numberWithUnsignedInt: theNextID]];
    theNextID++;

    userInfo = [NSDictionary dictionaryWithObject: [aFileStore storeID]
                                           forKey: LiFileStoreAdded];
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName: LiFileStoresChangedNotification
                                 object: nil
                               userInfo: userInfo];
}

+ (void)removeStoreWithID: (id)aStoreID
{
    NSDictionary *userInfo;
    NSNotificationCenter *defaultCenter;
    
    [[self fileStores] removeObjectForKey: aStoreID];

    userInfo = [NSDictionary dictionaryWithObject: aStoreID
                                           forKey: LiFileStoreRemoved];
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName: LiFileStoresChangedNotification
                                 object: nil
                               userInfo: userInfo];
}

+ (LiFileStore *)fileStoreWithName: (NSString *)aName
{
    return [[[self alloc] initWithName: aName] autorelease];
}

+ (NSImage *)defaultIcon
{
    return nil;
}

- (LiFileStore *)initWithName: (NSString *)aName
{
    self = [super init];

    [self setName: aName];
    [self setIcon: [[self class] defaultIcon]];
    nextHandle = 1;
    theFiles = [[NSMutableDictionary alloc] init];

    [LiFileStore addStore: self];

    return self;
}

- (id)init
{
    NSException *myException;

    [self autorelease];

    myException = [NSException exceptionWithName: @"LiFileStoreInitFailure"
                                          reason: @"[[LiFileStore alloc] init] isn't supported."
                                        userInfo: nil];
    [myException raise];
    return nil;
}

- (void)dealloc
{
    [LiFileStore removeStoreWithID: [self storeID]];
    [theFiles release];
    [theIndexes release];

    [super dealloc];
}

- (id)copyWithZone: (NSZone *)aZone
{
    LiFileStore *tmpStore;

    [LiLog logAsDebug: @"[LiFileStore copyWithZone: %@]", aZone];
    
    tmpStore = [[LiFileStore allocWithZone: aZone] initWithName: [self name]];
    [tmpStore setEditable: [self isEditable]];
    [tmpStore setIcon: [self icon]];

    // XXX
    tmpStore->theFiles = theFiles;
    tmpStore->theIndexes = theIndexes;
    tmpStore->nextHandle = nextHandle;

    return tmpStore;
}

- (id)initWithCoder: (NSCoder *)aCoder
{
    [LiLog logAsDebug: @"[LiFileStore initWithCoder: aCoder]"];
    
    self = [self init];
    if (self != nil) {
        NSData *iconData;
        NSDictionary *fileDB, *indexes;
        NSNumber *isEditable, *myNextHandle;
        NSString *name;

        if ([aCoder allowsKeyedCoding]) {
            name = [aCoder decodeObjectForKey: @"LiFSName"];
            iconData = [aCoder decodeObjectForKey: @"LiFSIconData"];
            isEditable = [aCoder decodeObjectForKey: @"LiFSIsEditable"];
            myNextHandle = [aCoder decodeObjectForKey: @"LiFSNextHandle"];
            fileDB = [aCoder decodeObjectForKey: @"LiFSFileDictionary"];
            indexes = [aCoder decodeObjectForKey: @"LiFSIndexes"];
        } else {
            name = [aCoder decodeObject];
            iconData = [aCoder decodeObject];
            isEditable = [aCoder decodeObject];
            myNextHandle = [aCoder decodeObject];
            fileDB = [aCoder decodeObject];
            indexes = [aCoder decodeObject];
        }
        [self setName: name];
        [self setIcon: [[[NSImage alloc] initWithData: iconData] autorelease]];
        [self setEditable: [isEditable boolValue]];
        nextHandle = [myNextHandle unsignedLongValue];
        theFiles = [[NSMutableDictionary alloc] initWithDictionary: fileDB];
        theIndexes = [[NSMutableDictionary alloc] initWithDictionary: indexes];
    }
    
    return self;
}

- (void)encodeWithCoder: (NSCoder *)aCoder
{
    [LiLog logAsDebug: @"[LiFileStore encodeWithCoder: aCoder]"];
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject: [self name]
                      forKey: @"LiFSName"];
        [aCoder encodeObject: [[self icon] TIFFRepresentation]
                      forKey: @"LiFSIconData"];
        [aCoder encodeObject: [NSNumber numberWithBool: [self isEditable]]
                      forKey: @"LiFSIsEditable"];
        [aCoder encodeObject: [NSNumber numberWithUnsignedLong: nextHandle]
                      forKey: @"LiFSNextHandle"];
        [aCoder encodeObject: theFiles
                      forKey: @"LiFSFileDictionary"];
        [aCoder encodeObject: theIndexes
                      forKey: @"LiFSIndexes"];
    } else {
        [aCoder encodeObject: [self name]];
        [aCoder encodeObject: [[self icon] TIFFRepresentation]];
        [aCoder encodeObject: [NSNumber numberWithBool: [self isEditable]]];
        [aCoder encodeObject: [NSNumber numberWithUnsignedLong: nextHandle]];
        [aCoder encodeObject: theFiles];
        [aCoder encodeObject: theIndexes];
    }
}

- (void)addIndexForAttribute: (NSString *)anAttribute
{
    NSEnumerator *fileEnum;
    NSMutableDictionary *newIndex;
    id fileHandle;

    if ([self indexForAttribute: anAttribute] == nil) {
        NSMutableArray *filesInValue;

        [LiLog logAsDebug: @"Indexing %@.", anAttribute];
        
        filesInValue = [NSMutableArray array];
        newIndex = [NSMutableDictionary dictionary];
        fileEnum = [theFiles keyEnumerator];
        while ((fileHandle = [fileEnum nextObject]) != nil) {
            id value;

            value = [[theFiles objectForKey: fileHandle] objectForKey: anAttribute];
            if (value != nil) {
                if ([value isKindOfClass: [NSArray class]]) {
                    NSEnumerator *valEnum;
                    id subValue;

                    valEnum = [value objectEnumerator];
                    while ((subValue = [valEnum nextObject]) != nil) {
                        filesInValue = [newIndex objectForKey: subValue];
                        if (filesInValue == nil) {
                            filesInValue = [NSMutableArray array];
                            [newIndex setObject: filesInValue forKey: subValue];
                        }
                        [filesInValue addObject: fileHandle];
                    }
                } else {
                    filesInValue = [newIndex objectForKey: value];
                    if (filesInValue == nil) {
                        filesInValue = [NSMutableArray array];
                        [newIndex setObject: filesInValue forKey: value];
                    }
                    [filesInValue addObject: fileHandle];
                }
            }
        }

        if (theIndexes == nil)
            theIndexes = [[NSMutableDictionary alloc] init];
        [theIndexes setObject: newIndex forKey: anAttribute];

        [LiLog logAsDebug: @"Done indexing %@.", anAttribute];
    }
}

- (NSMutableDictionary *)indexForAttribute: (NSString *)anAttribute
{
    return [theIndexes objectForKey: anAttribute];
}

- (void)removeIndexForAttribute: (NSString *)anAttribute
{
    if ([theIndexes objectForKey: anAttribute] != nil)
        [theIndexes removeObjectForKey: anAttribute];
}

- (id)fileIDWithAttributes: (NSDictionary *)someAttributes
{
    NSEnumerator *attrEnum;
    NSString *attribute;
    NSMutableDictionary *fileAttributes;
    NSNumber *handle;
    
    handle = [someAttributes objectForKey: LiFileHandleAttribute];
    if (handle == nil) {
        handle = [NSNumber numberWithUnsignedLong: nextHandle];
        nextHandle++;
    } else if ([theFiles objectForKey: handle] != nil) {
        return handle;
    } else
        if (nextHandle <= [handle unsignedLongValue])
            nextHandle = [handle unsignedLongValue]+1;
    
    // First, create the file.
    fileAttributes = [NSMutableDictionary dictionaryWithDictionary: someAttributes];
    [fileAttributes setObject: handle forKey: LiFileHandleAttribute];
    [theFiles setObject: fileAttributes forKey: handle];
    
    // Then update indexes.
    attrEnum = [someAttributes keyEnumerator];
    while ((attribute = [attrEnum nextObject]) != nil) {
        NSMutableDictionary *index;
        
        index = [self indexForAttribute: attribute];
        if (index != nil) {
            id myValue;
            
            myValue = [someAttributes objectForKey: attribute];
            if (myValue != nil) {
                NSMutableArray *fileArray;
                
                if ([myValue isKindOfClass: [NSArray class]]) {
                    NSEnumerator *valEnum;
                    id subValue;
                    
                    valEnum = [myValue objectEnumerator];
                    while ((subValue = [valEnum nextObject]) != nil) {
                        fileArray = [index objectForKey: subValue];
                        if (fileArray == nil) {
                            fileArray = [NSMutableArray array];
                            [index setObject: fileArray forKey: subValue];
                        }
                        [fileArray addObject: handle];
                    }
                } else {
                    fileArray = [index objectForKey: myValue];
                    if (fileArray == nil) {
                        fileArray = [NSMutableArray array];
                        [index setObject: fileArray forKey: myValue];
                    }
                    [fileArray addObject: handle];
                }
            }
        }
    }
    
    if (handle != nil)
        [self sendAddNotificationForFileHandle: [LiFileHandle fileHandleWithID: handle storeID: [self storeID]]];
    return handle;
}

- (void)updateFileID: (id)aFileID
      withAttributes: (NSDictionary *)someAttributes
{
    NSString *attribute;
    NSEnumerator *attrEnum;
    NSMutableDictionary *oldAttributes, *newAttributes, *tmpAttributes;
    
    // Call the delegate's sync method with the new attributes.
    // Allow the delegate to filter out attributes it can't modify
    // or modify attributes if it has to.
    // It should return a dict of what was modified.
    newAttributes = [NSMutableDictionary dictionaryWithDictionary:
        someAttributes];
    [[self delegate] synchronizeFileHandle: [LiFileHandle fileHandleWithID: aFileID
                                                                   storeID: [self storeID]]
                         withNewAttributes: newAttributes];
    
    oldAttributes = [theFiles objectForKey: aFileID];
    tmpAttributes = [NSMutableDictionary dictionary];
    attrEnum = [newAttributes keyEnumerator];
    while ((attribute = [attrEnum nextObject]) != nil) {
        NSMutableDictionary *index;
        id oldValue, newValue;
        
        oldValue = [oldAttributes objectForKey: attribute];
        newValue = [newAttributes objectForKey: attribute];
        
        // For notification.
        if (oldValue != nil)
            [tmpAttributes setObject: oldValue forKey: attribute];
        
        index = [self indexForAttribute: attribute];
        if (index != nil) {
            NSMutableArray *fileArray;
            
            // Remove old values from index.
            if (oldValue != nil) {
                if ([oldValue isKindOfClass: [NSArray class]]) {
                    NSEnumerator *valEnum;
                    id subValue;
                    
                    valEnum = [oldValue objectEnumerator];
                    while ((subValue = [valEnum nextObject]) != nil) {
                        fileArray = [index objectForKey: subValue];
                        [fileArray removeObject: aFileID];
                        if ([fileArray count] == 0) {
                            [index removeObjectForKey: subValue];
                        }
                    }
                } else {
                    fileArray = [index objectForKey: oldValue];
                    [fileArray removeObject: aFileID];
                    if ([fileArray count] == 0) {
                        [index removeObjectForKey: oldValue];
                    }
                }
            }
            
            // Add new values to index.
            if ([newValue isKindOfClass: [NSArray class]]) {
                NSEnumerator *valEnum;
                id subValue;
                
                valEnum = [newValue objectEnumerator];
                while ((subValue = [valEnum nextObject]) != nil) {
                    fileArray = [index objectForKey: subValue];
                    if (fileArray == nil) {
                        fileArray = [NSMutableArray array];
                        [index setObject: fileArray forKey: subValue];
                    }
                    [fileArray addObject: aFileID];
                }
            } else {
                fileArray = [index objectForKey: newValue];
                if (fileArray == nil) {
                    fileArray = [NSMutableArray array];
                    [index setObject: fileArray forKey: newValue];
                }
                [fileArray addObject: aFileID];
            }
        }
        
        if (newValue == nil) {
            [oldAttributes removeObjectForKey: attribute];
        } else
            [oldAttributes setObject: newValue forKey: attribute];
    }

    // Send notification of update if there's something to say.
    if ([newAttributes count] > 0) {
        [self sendUpdateNotificationForFileHandle: [LiFileHandle fileHandleWithID: aFileID storeID: [self storeID]]
                                    oldAttributes: tmpAttributes];
    }
}

- (void)removeFileID: (id)aFileID
{
    NSDictionary *fileAttrs;
    
    fileAttrs = [theFiles objectForKey: aFileID];
    if (fileAttrs != nil) {
        NSEnumerator *attrEnum;
        NSString *attribute;
        
        attrEnum = [fileAttrs keyEnumerator];
        while ((attribute = [attrEnum nextObject]) != nil) {
            NSMutableDictionary *index;
            id myValue;
            
            myValue = [fileAttrs objectForKey: attribute];
            index = [self indexForAttribute: attribute];
            if (index != nil) {
                NSMutableArray *fileArray;
                
                if ([myValue isKindOfClass: [NSArray class]]) {
                    NSEnumerator *valEnum;
                    id subValue;
                    
                    valEnum = [myValue objectEnumerator];
                    while ((subValue = [valEnum nextObject]) != nil) {
                        fileArray = [index objectForKey: subValue];
                        [fileArray removeObject: aFileID];
                        if ([fileArray count] == 0)
                            [index removeObjectForKey: subValue];
                    }
                } else {
                    fileArray = [index objectForKey: myValue];
                    [fileArray removeObject: aFileID];
                    if ([fileArray count] == 0)
                        [index removeObjectForKey: myValue];
                }
            }
        }
        
        [fileAttrs retain];
        [theFiles removeObjectForKey: aFileID];

        // Send notification of removal.
        if ([fileAttrs count] > 0) {
            [self sendRemoveNotificationForFileHandle: [LiFileHandle fileHandleWithID: aFileID storeID: [self storeID]]
                                        oldAttributes: fileAttrs];
        }
        [fileAttrs release];
    }
}

- (NSDictionary *)attributesForFileID: (id)aFileID
{
    return [theFiles objectForKey: aFileID];
}

- (NSArray *)allFileIDs
{
    return [theFiles allKeys];
}

- (NSDictionary *)fileIDsMatchingFilter: (LiFilter *)aFilter
                                 inList: (NSDictionary *)someFiles
{
    if (aFilter != nil) {
        NSDictionary *index;
        NSMutableDictionary *matchingFiles;
        
        matchingFiles = nil;
        index = [self indexForAttribute: [aFilter attribute]];
        if (index != nil && [someFiles count] > [index count]) {
            NSEnumerator *valEnum;
            id value;
            
            valEnum = [index keyEnumerator];
            while ((value = [valEnum nextObject]) != nil) {
                if ([value performSelector: [aFilter compareSelector]
                                withObject: [aFilter value]]) {
                    NSEnumerator *idEnum;
                    id fileID;
                    
                    if (matchingFiles == nil)
                        matchingFiles = [NSMutableDictionary dictionary];
                    
                    idEnum = [[index objectForKey: value] objectEnumerator];
                    while ((fileID = [idEnum nextObject]) != nil) {
                        [matchingFiles setObject: [self attributesForFileID: fileID]
                                          forKey: fileID];
                    }
                }
            }
        } else { // Non-indexed
            NSEnumerator *idEnum;
            id fileID;
            
            // Go through all the files in the list.
            idEnum = [someFiles keyEnumerator];
            while ((fileID = [idEnum nextObject]) != nil) {
                if ([self attributes: [someFiles objectForKey: fileID]
                         matchFilter: aFilter]) {
                    if (matchingFiles == nil)
                        matchingFiles = [NSMutableDictionary dictionary];
                    [matchingFiles setObject: [self attributesForFileID: fileID]
                                      forKey: fileID];
                }
            }
        }
        return matchingFiles;
    } else
        return someFiles;
}

- (NSArray *)fileIDsMatchingFilter: (LiFilter *)aFilter
{
    NSArray *matchingFiles;
    if (aFilter != nil) {
        matchingFiles = [[self fileIDsMatchingFilter: aFilter inList: theFiles] allKeys];
    } else
        matchingFiles = [self allFileIDs];

    return matchingFiles;
}

- (BOOL)attributes: (NSDictionary *)someAttributes
       matchFilter: (LiFilter *)aFilter
{
    if (aFilter == nil)
        return YES;
    else if (someAttributes != nil) {
        id myValue;

        myValue = [someAttributes objectForKey: [aFilter attribute]];
        if ([myValue respondsToSelector: @selector(objectEnumerator)]) {
            NSEnumerator *valueEnum;
            id subValue;

            valueEnum = [myValue performSelector: @selector(objectEnumerator)];
            while ((subValue = [valueEnum nextObject]) != nil) {
                if ([subValue respondsToSelector: [aFilter compareSelector]]) {
                    if ([subValue performSelector: [aFilter compareSelector]
                                       withObject: [aFilter value]]) {
                        return YES;
                    }
                }
            }
            return NO;
        } else { // Non-enumerable
            BOOL match;

            match = NO;
            if ([myValue respondsToSelector: [aFilter compareSelector]])
                if ([myValue performSelector: [aFilter compareSelector]
                                  withObject: [aFilter value]])
                    match = YES;
            return match;
        }
    } else
        return NO;
}

#if 0
- (BOOL)attributes: (NSDictionary *)someAttributes
             match: (NSDictionary *)matchAttributes
{
    BOOL matches;

    matches = YES;
    if (someAttributes != nil && [someAttributes count] > 0) {
        NSEnumerator *attrEnum;
        NSString *attribute;

        attrEnum = [someAttributes keyEnumerator];
        while ((attribute = [attrEnum nextObject]) != nil) {
            id myValue, matchValue;

            matchValue = [someAttributes objectForKey: attribute];
            myValue = [someAttributes objectForKey: attribute];
            if (matchValue != myValue) {
                if ([myValue isKindOfClass: [NSArray class]]) {
                    NSEnumerator *valEnum;
                    id subValue;

                    valEnum = [myValue objectEnumerator];
                    while ((subValue = [valEnum nextObject]) != nil) {
                        if (subValue != matchValue) {
                            if ([subValue respondsToSelector:
                                @selector(compare:)]) {
                                if ([subValue performSelector: @selector(compare:)
                                                   withObject: matchValue] != 0)
                                    matches = NO;
                            } else
                                matches = NO;
                        }
                    }
                } else if ([myValue respondsToSelector:
                    @selector(compare:)]) {
                    if ([myValue performSelector: @selector(compare:)
                                      withObject: matchValue] != 0)
                        matches = NO;
                } else
                    matches = NO;
            }
        }
    }

    return matches;
}

- (NSMutableSet *)filesInSet: (NSMutableSet *)fileSet
          matchingAttributes: (NSMutableDictionary *)someAttributes
{
    NSEnumerator *attributeEnum;
    NSString *attribute, *bestAttribute;
    id attributeValue;
    long bestCount;
    
    if (someAttributes == nil || [someAttributes count] == 0)
        return fileSet;
    
    // Find the smallest sets of potential matchers. This allows us to look
    // up as few files as possible.
    bestAttribute = nil;
    bestCount = -1;
    attributeEnum = [someAttributes keyEnumerator];
    while ((attribute = [attributeEnum nextObject]) != nil) {
        if (bestAttribute == nil)
            bestAttribute = attribute;
        else {
            NSDictionary *index;
            
            index = [self indexForAttribute: attribute];
            if (index != nil) {
                unsigned long indexCount;
                
                indexCount = [index count];
                if (bestCount == -1) {
                    bestAttribute = attribute;
                    bestCount = indexCount;
                } else if (bestCount > 1 && bestCount > (long)indexCount) {
                    bestAttribute = attribute;
                    bestCount = indexCount;
                }
            }
        }
    }
    attribute = bestAttribute;
    attributeValue = [someAttributes objectForKey: bestAttribute];
    
    if (fileSet == nil) {
        NSDictionary *index;
        
        index = [self indexForAttribute: attribute];
        if (index != nil) {
            fileSet = [NSMutableSet setWithArray: [index objectForKey: attributeValue]];
        } else {
            NSEnumerator *handleEnum;
            id handle;
            
            // Go through every file in the library one by one. Shitty!
            fileSet = [NSMutableSet set];
            handleEnum = [theFiles keyEnumerator];
            while ((handle = [handleEnum nextObject]) != nil) {
                NSDictionary *handleAttrs;
                id myValue;
                
                handleAttrs = [theFiles objectForKey: handle];
                myValue = [handleAttrs objectForKey: attribute];
                if (myValue != attributeValue) {
                    if ([myValue isKindOfClass: [NSArray class]]) {
                        NSEnumerator *valueEnum;
                        id subValue;
                        
                        valueEnum = [myValue objectEnumerator];
                        while ((subValue = [valueEnum nextObject]) != nil) {
                            if (subValue == attributeValue)
                                [fileSet addObject: handle];
                            else if ([subValue respondsToSelector: @selector(compare:)]) {
                                if ([subValue performSelector: @selector(compare:)
                                                   withObject: attributeValue] == 0) {
                                    [fileSet addObject: handle];
                                    break;
                                }
                            }
                        }
                    } else if ([myValue respondsToSelector: @selector(compare:)])
                        if ([myValue performSelector: @selector(compare:)
                                          withObject: attributeValue] == 0)
                            [fileSet addObject: handle];
                } else
                    [fileSet addObject: handle];
            }
        }
    } else {
        NSDictionary *index;
        
        index = [self indexForAttribute: attribute];
        if (index != nil) {
            [fileSet intersectSet: [NSMutableSet setWithArray: [index objectForKey: attributeValue]]];
        } else {
            NSEnumerator *handleEnum;
            id handle;
            
            // Go through every file in the set.
            handleEnum = [fileSet objectEnumerator];
            while ((handle = [handleEnum nextObject]) != nil) {
                NSDictionary *handleAttrs;
                id myValue;
                
                handleAttrs = [theFiles objectForKey: handle];
                myValue = [handleAttrs objectForKey: attribute];
                if (myValue == attributeValue) {
                    [fileSet removeObject: handle];
                } else if ([myValue respondsToSelector: @selector(compare:)]) {
                    if ([myValue performSelector: @selector(compare:)
                                      withObject: attributeValue] == 0)
                        [fileSet removeObject: handle];
                }
            }
        }
    }
    
    [someAttributes removeObjectForKey: bestAttribute];
    return [self filesInSet: fileSet matchingAttributes: someAttributes];
}

- (NSArray *)filesMatchingAttributes: (NSDictionary *)someAttributes
{
    if (someAttributes != nil && [someAttributes count] > 0) {
        NSEnumerator *handleEnum;
        NSMutableArray *matchingFiles;
        id handle;
        
        matchingFiles = [NSMutableArray array];
        handleEnum = [[self filesInSet: nil
                    matchingAttributes: [NSMutableDictionary dictionaryWithDictionary: someAttributes]] objectEnumerator];
        while ((handle = [handleEnum nextObject]) != nil) {
            LiFileHandle *fileHandle;
            
            fileHandle = [[LiFileHandle alloc] init];
            [fileHandle setFileStore: self];
            [fileHandle setFileHandle: handle];
            
            [matchingFiles addObject: fileHandle];
            [fileHandle release];
        }
        return matchingFiles;
    } else
        return [self allFileHandles];
}
#endif

- (NSArray *)allValuesForAttribute: (NSString *)anAttribute
{
    NSArray *valueArray;
    NSMutableDictionary *index;
    NSMutableSet *values;

    values = [NSMutableSet setWithArray: [[self delegate] defaultValuesForAttribute: anAttribute]];
    index = [self indexForAttribute: anAttribute];
    if (index != nil) {
        // Use the index to find the possible values.
        [values addObjectsFromArray: [index allKeys]];
    } else {
        NSDictionary *fileAttrs;
        NSEnumerator *fileEnum;
        
        // No index. Crappy. Go through every file in the library.
        fileEnum = [theFiles objectEnumerator];
        while ((fileAttrs = [fileEnum nextObject]) != nil) {
            id value;

            value = [fileAttrs objectForKey: anAttribute];
            if (value != nil && [values member: anAttribute] != nil) {
                [values addObject: anAttribute];
            }
        }
    }

    valueArray = [values allObjects];
    return valueArray;
}
@synthesize theIcon;
@synthesize theDelegate;
@synthesize theFiles;
@synthesize nextHandle;
@synthesize theStoreID;
@synthesize theName;
@synthesize theIndexes;
@end

@implementation LiFileStore (CommonAccessors)
- (void)synchronize
{
    if ([self sendNotifications] > 0) {
        [[self delegate] synchronizeFileStore];
    }
}

- (LiFileHandle *)addURL: (NSURL *)anURL
{
    return [[self delegate] addURL: anURL toFileStore: self];
}
@end

@implementation LiFileStore (Accessors)
- (id)storeID
{
    return theStoreID;
}

- (void)setStoreID: (id)anID
{
    [anID retain];
    [theStoreID release];
    theStoreID = anID;
}

- (id <LiFileStoreDelegate>)delegate
{
    return theDelegate;
}

- (void)setDelegate: (id <LiFileStoreDelegate>)aDelegate
{
    [aDelegate retain];
    [theDelegate release];
    theDelegate = aDelegate;
}

- (BOOL)isEditable
{
    return theStoreIsEditable;
}

- (void)setEditable: (BOOL)editable
{
    theStoreIsEditable = editable;
}

- (NSString *)name
{
    return theName;
}

- (void)setName: (NSString *)aName
{
    NSNotificationCenter *defaultCenter;
    
    [aName retain];
    [theName release];
    theName = aName;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName: LiFileStoresChangedNotification
                                 object: nil
                               userInfo: nil];
}

- (NSImage *)icon
{
    return theIcon;
}

- (void)setIcon: (NSImage *)anIcon
{
    NSNotificationCenter *defaultCenter;
    
    [anIcon retain];
    [theIcon release];
    theIcon = anIcon;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName: LiFileStoresChangedNotification
                                 object: nil
                               userInfo: nil];
}

- (NSMutableSet *)addedFiles
{
    if (theAddedFiles == nil)
        [self setAddedFiles: [NSMutableSet set]];
    return theAddedFiles;
}

- (void)setAddedFiles: (NSMutableSet *)aSet
{
    [aSet retain];
    [theAddedFiles release];
    theAddedFiles = aSet;
}

- (NSMutableSet *)changedFiles
{
    if (theChangedFiles == nil)
        [self setChangedFiles: [NSMutableSet set]];
    return theChangedFiles;
}

- (void)setChangedFiles: (NSMutableSet *)aSet
{
    [aSet retain];
    [theChangedFiles release];
    theChangedFiles = aSet;
}

- (NSMutableSet *)removedFiles
{
    if (theRemovedFiles == nil)
        [self setRemovedFiles: [NSMutableSet set]];
    return theRemovedFiles;
}

- (void)setRemovedFiles: (NSMutableSet *)aSet
{
    [aSet retain];
    [theRemovedFiles release];
    theRemovedFiles = aSet;
}
@end

@implementation LiFileStore (Scripting)
- (NSScriptObjectSpecifier *)objectSpecifier
{
    NSScriptClassDescription *containerDescription;
    NSScriptObjectSpecifier *containerRef;
    unsigned index;

    index = [[LiFileStore allFileStores] indexOfObjectIdenticalTo: self];
    if (index != NSNotFound) {
        containerRef = [NSApp objectSpecifier];
        containerDescription = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];

        return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerDescription containerSpecifier:containerRef key:@"orderedFileStores" index:index] autorelease];
    } else
        return nil;
}
@end

@implementation LiFileStore (Private)
// XXX
// Should coalesce like events into a single event before sending it
// and take the array code out of the individual file updates.
- (void)sendNotificationName: (NSString *)aNotificationName
                    userInfo: (NSDictionary *)userInfo
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName: aNotificationName
                                 object: self
                               userInfo: userInfo];
}

- (unsigned)sendNotifications
{
    NSMutableDictionary *userInfo;
    unsigned changeCount;

    userInfo = [NSMutableDictionary dictionary];
    if ([[self addedFiles] count] > 0) {
        [userInfo setObject: [[self addedFiles] allObjects]
                     forKey: LiFilesAdded];
        [self setAddedFiles: nil];
    }
    if ([[self changedFiles] count] > 0) {
        [userInfo setObject: [[self changedFiles] allObjects]
                     forKey: LiFilesChanged];
        [self setChangedFiles: nil];
    }
    if ([[self removedFiles] count] > 0) {
        [userInfo setObject: [[self removedFiles] allObjects]
                     forKey: LiFilesRemoved];
        [self setRemovedFiles: nil];
    }

    changeCount = [userInfo count];
    if (changeCount > 0) {
        [self sendNotificationName: LiFileChangedNotification
                          userInfo: userInfo];
    }
    return changeCount;
}

- (void)sendAddNotificationForFileHandle: (LiFileHandle *)aFileHandle
{
    [[self addedFiles] addObject: aFileHandle];
}

- (void)sendUpdateNotificationForFileHandle: (LiFileHandle *)aFileHandle
                              oldAttributes: (NSDictionary *)oldAttrs
{
    if ([oldAttrs count] > 0) {
        [[self changedFiles] addObject:
            [NSDictionary dictionaryWithObjects:
                [NSArray arrayWithObjects: aFileHandle, oldAttrs, nil]
                                        forKeys:
                [NSArray arrayWithObjects: LiFileHandleAttribute, LiFileOldAttributes, nil]]];
    }
}

- (void)sendRemoveNotificationForFileHandle: (LiFileHandle *)aFileHandle
                              oldAttributes: (NSDictionary *)oldAttrs
{
    [[self removedFiles] addObject:
        [NSDictionary dictionaryWithObjects:
            [NSArray arrayWithObjects: aFileHandle, oldAttrs, nil]
                                    forKeys:
            [NSArray arrayWithObjects: LiFileHandleAttribute, LiFileOldAttributes, nil]]];
}
@end