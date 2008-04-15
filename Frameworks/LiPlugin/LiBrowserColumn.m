//
//  LiBrowserColumn.m
//  Liaison
//
//  Created by Brian Cully on Thu May 15 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiBrowserColumn.h"

@implementation LiBrowserColumn
- (id)init
{
    self = [super init];

    [self setResizable: YES];
    
    return self;
}

- (void)dealloc
{
    [self setName: nil];
    [super dealloc];
}

- (id)objectForRecord: (id)aRecord
{
    return [aRecord performSelector: [self getMethod]];
}

- (void)setObject: (id)anObject forRecord: (id)aRecord
{
    [aRecord performSelector: [self setMethod] withObject: anObject];
}
@synthesize theCell;
@synthesize theIdentifier;
@synthesize theWidth;
@synthesize theColumnName;
@end

@implementation LiBrowserColumn (Accessors)
- (id)identifier
{
    return theIdentifier;
}

- (void)setIdentifier: (id)anIdentifier
{
    [anIdentifier retain];
    [theIdentifier release];
    theIdentifier = anIdentifier;
}

- (NSString *)name
{
    return theColumnName;
}

- (void)setName: (NSString *)aName
{
    [aName retain];
    [theColumnName release];
    theColumnName = aName;
}

- (BOOL)editable
{
    return theColumnIsEditable;
}

- (void)setEditable: (BOOL)editable
{
    theColumnIsEditable = editable;
}

- (BOOL)resizable
{
    return theColumnIsResizable;
}

- (void)setResizable: (BOOL)resizable
{
    theColumnIsResizable = resizable;
}

- (BOOL)showsHeader
{
    return theColumnShowsHeader;
}

- (void)setShowsHeader: (BOOL)showHeader
{
    theColumnShowsHeader = showHeader;
}

- (NSCell *)cell
{
    return theCell;
}

- (void)setCell: (NSCell *)aCell
{
    [aCell retain];
    [theCell release];
    theCell = aCell;
}

- (SEL)getMethod
{
    return theGetMethod;
}

- (void)setGetMethod: (SEL)aSelector
{
    theGetMethod = aSelector;
}

- (SEL)setMethod
{
    return theSetMethod;
}

- (void)setSetMethod: (SEL)aSelector
{
    theSetMethod = aSelector;
}

- (SEL)compareMethod
{
    return theCompareMethod;
}

- (void)setCompareMethod: (SEL)aSelector
{
    theCompareMethod = aSelector;
}

- (NSNumber *)width
{
    return theWidth;
}

- (void)setWidth: (NSNumber *)aWidth
{
    [aWidth retain];
    [theWidth release];
    theWidth = aWidth;
}
@end
