//
//  Group.m
//  Liaison
//
//  Created by Brian Cully on Tue Feb 04 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//
#import "Group.h"

@implementation Group (Copying)
- (id)copyWithZone: (NSZone *)aZone
{
    Group *tmpGroup;
    
    tmpGroup = [[Group alloc] initWithName: [self name] andType: [self type]];
    [tmpGroup setIcon: [self icon]];
    [tmpGroup setFileStore: [self fileStore]];
    tmpGroup->parent = parent; // XXX
    tmpGroup->children = children; // XXX
    
    return tmpGroup;
}

- (unsigned)hash
{
    unsigned nameHash, storeHash;
    
    storeHash = (unsigned)[[[self fileStore] storeID] performSelector: @selector(hash)];
    nameHash = [[self name] hash];
    return (storeHash ^ nameHash);
}

- (BOOL)isEqual: (id)anObject
{
    if ([anObject isKindOfClass: [self class]]) {
        Group *otherGroup;
        id myStoreID, otherStoreID;
        
        myStoreID = [[self fileStore] storeID];
        otherGroup = anObject;
        otherStoreID = [[otherGroup fileStore] storeID];
        
        if ([myStoreID performSelector: @selector(compare:) withObject: otherStoreID] &&
            [[self name] isEqualToString: [otherGroup name]])
            return YES;
        else
            return NO;
    }
    
    return NO;
}
@end

@implementation Group
+ (Group *)groupWithName: (NSString *)aName
{
    return [[[self alloc] initWithName: aName] autorelease];
}

+ (Group *)groupWithName: (NSString *)aName andType: (GroupType)aType
{
    return [[[self alloc] initWithName: aName andType: aType] autorelease];
}

- (Group *)initWithName: (NSString *)aName
{
    return [self initWithName: aName andType: BRANCH];
}

- (Group *)initWithName: (NSString *)aName andType: (GroupType)aType;
{
    self = [super init];

    [self setName: aName];
    [self setType: aType];
    icon = [[NSImage imageNamed: LiNormalGroupIcon] retain];
    children = [[NSMutableArray alloc] init];

    return self;
}

- (id)init
{
    NSException *myException;

    [self autorelease];

    myException = [NSException exceptionWithName: @"GroupInitFailure"
                                          reason: @"[[Group alloc] init] isn't supported."
                                        userInfo: nil];
    [myException raise];
    return nil;
}

- (void)dealloc
{
    [self setName: nil];
    [icon release];
    [children release];
    [self setFileStore: nil];

    [super dealloc];
}

- (id)initWithContentsOfFile: (NSString *)aFilename
{
    NSArray *groupArray;
    NSDictionary *groupDict;
    NSString *groupname;

    groupDict = [NSDictionary dictionaryWithContentsOfFile: aFilename];
    self = [self initWithName: [groupDict objectForKey: @"name"]];

    groupArray = [groupDict objectForKey: @"children"];
    for (groupname in groupArray) {
        Group *newGroup;

        // XXX - should encode type
        newGroup = [[[Group alloc] initWithName: groupname
                                        andType: LEAF] autorelease];
        [newGroup setIcon: [NSImage imageNamed: LiNormalGroupIcon]];
        [self addChild: newGroup];
    }
    return self;
}

- (BOOL)writeToFile: (NSString *)aFilename
{
    Group *group;
    NSMutableArray *groupArray;
    NSMutableDictionary *groupDict;

    groupDict = [NSMutableDictionary dictionary];

    groupArray = [NSMutableArray array];
    for (group in children) {
        [groupArray addObject: [group name]];
    }

    [groupDict setObject: name forKey: @"name"];
    [groupDict setObject: groupArray forKey: @"children"];

    return [groupDict writeToFile: aFilename atomically: NO];
}

- (LiFileStore *)fileStore
{
    return theFileStore;
}

- (void)setFileStore: (LiFileStore *)aFileStore
{
    [aFileStore retain];
    [theFileStore release];
    theFileStore = aFileStore;
}

- (id)initWithCoder: (NSCoder *)coder
{
    NSString *typeString;
    
    self = [super init];

    if ([coder allowsKeyedCoding]) {
        [self setName: [coder decodeObjectForKey: @"name"]];
        typeString = [coder decodeObjectForKey: @"type"];
        children = [[coder decodeObjectForKey: @"children"] retain];
    } else {
        [self setName: [coder decodeObject]];
        typeString = [coder decodeObject];
        children = [[coder decodeObject] retain];
    }

    if ([typeString isEqualToString: @"LEAF"])
        [self setType: LEAF];
    else
        [self setType: BRANCH];

    icon = [[NSImage imageNamed: LiNormalGroupIcon] retain];

    return self;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
    NSString *typeString;

    if ([self type] == LEAF)
        typeString = @"LEAF";
    else
        typeString = @"BRANCH";

    if ([coder allowsKeyedCoding]) {
        [coder encodeObject: [self name] forKey: @"name"];
        [coder encodeObject: typeString forKey: @"type"];
        [coder encodeObject: children forKey: @"children"];
    } else {
        [coder encodeObject: [self name]];
        [coder encodeObject: typeString];
        [coder encodeObject: children];
    }
}

- (NSString *)name
{
    return name;
}

- (GroupType)type
{
    return type;
}

- (void)setName: (NSString *)aName
{
    [aName retain];
    [name release];
    name = aName;
}

- (void)setType: (GroupType)aType
{
    type = aType;
}

- (NSImage *)icon
{
    return icon;
}

- (void)setIcon: (NSImage *)anIcon
{
    [anIcon retain];
    [icon release];
    icon = anIcon;
}

- (Group *)parent
{
    return parent;
}

- (void)setParent: (Group *)aParent
{
    [aParent retain];
    [parent release];
    parent = aParent;
}

- (int)numberOfChildren
{
    return [children count];
}

- (BOOL)hasChild: (id)aChild
{
    return [children containsObject: aChild];
}

- (NSEnumerator *)childEnumerator
{
    return [children objectEnumerator];
}

- (void)addChild: (id)aChild
{
    [children addObject: aChild];
    [aChild setParent: self];
}

- (void)removeChild: (id)aChild
{
    [aChild setParent: nil];
    [children removeObject: aChild];
}

- (Group *)childNamed: (NSString *)aName
{
    Group *child;
    int i, numberOfChildren;

    child = nil;
    numberOfChildren = [children count];
    for (i = 0; i < numberOfChildren; i++) {
        child = [children objectAtIndex: i];
        if ([[child name] isEqualToString: aName])
            break;
    }
    if (i < numberOfChildren)
        return child;
    return nil;
}

- (void)removeChildNamed: (NSString *)aName
{
    int i, numberOfChildren;

    numberOfChildren = [children count];
    for (i = 0; i < numberOfChildren; i++) {
        Group *child;

        child = [children objectAtIndex: i];
        if ([[child name] isEqualToString: aName])
            break;
    }
    if (i < numberOfChildren)
        [children removeObjectAtIndex: i];
}

- (id)childAtIndex: (int)index
{
    return [children objectAtIndex: index];
}

- (void)removeChildAtIndex: (int)index
{
    [children removeObjectAtIndex: index];
}
@synthesize children;
@synthesize theFileStore;
@end
