//
//  Group.h
//  Liaison
//
//  Created by Brian Cully on Tue Feb 04 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

typedef enum _GroupType { LEAF, BRANCH } GroupType;

@interface Group : NSObject <NSCoding>
{
    NSString *name;
    GroupType type;
    NSImage *icon;
    NSMutableArray *children;
    Group *parent;

    LiFileStore *theFileStore;
}
+ (Group *)groupWithName: (NSString *)aName;
+ (Group *)groupWithName: (NSString *)aName andType: (GroupType)aType;
- (Group *)initWithName: (NSString *)aName;
- (Group *)initWithName: (NSString *)aName andType: (GroupType)aType;

- (id)initWithContentsOfFile: (NSString *)aFilename;
- (BOOL)writeToFile: (NSString *)aFilename;

- (LiFileStore *)fileStore;
- (void)setFileStore: (LiFileStore *)aFileStore;

- (NSString *)name;
- (GroupType)type;
- (void)setName: (NSString *)aName;
- (void)setType: (GroupType)aType;
- (NSImage *)icon;
- (void)setIcon: (NSImage *)anIcon;

- (Group *)parent;

- (int)numberOfChildren;
- (NSEnumerator *)childEnumerator;
- (BOOL)hasChild: (id)aChild;
- (void)addChild: (id)aChild;
- (void)removeChild: (id)aChild;
- (Group *)childNamed: (NSString *)aName;
- (void)removeChildNamed: (NSString *)aName;
- (id)childAtIndex: (int)index;
- (void)removeChildAtIndex: (int)index;
@property (retain) NSMutableArray *children;
@property (retain,getter=fileStore) LiFileStore *theFileStore;
@end
