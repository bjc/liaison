//
//  LiFilterDescription.m
//  LiFrameworks
//
//  Created by Brian Cully on Sat Aug 23 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiFilterDescription.h"

@implementation LiFilterDescription
+ (id)descriptionForMethod: (SEL)aMethod
                      name: (NSString *)aName
          compareOperators: (NSDictionary *)someOperators
           valueEditorCell: (NSCell *)aCell
{
    id tmpDesc;

    tmpDesc = [[self alloc] initWithMethod: aMethod
                                      name: aName
                          compareOperators: someOperators
                           valueEditorCell: aCell];
    return [tmpDesc autorelease];
}

- (id)init
{
    NSException *exception;

    exception = [NSException exceptionWithName: @"LiNoInitException"
                                        reason: @"[LiFilterDescription init] not supported"
                                      userInfo: nil];
    [exception raise];

    return nil;
}

- (void)dealloc
{
    [self setMethod: nil];
    [self setName: nil];
    [self setCompareOperators: nil];
    [self setValueEditorCell: nil];
    
    [super dealloc];
}

- (id)initWithMethod: (SEL)aMethod
                name: (NSString *)aName
    compareOperators: (NSDictionary *)someOperators
     valueEditorCell: (NSCell *)aCell
{
    self = [super init];

    [self setMethod: aMethod];
    [self setName: aName];
    [self setCompareOperators: someOperators];
    [self setValueEditorCell: aCell];
    
    return self;
}
@synthesize theName;
@synthesize theValueEditorCell;
@synthesize theCompareOperators;
@end

@implementation LiFilterDescription (Accessors)
- (SEL)method
{
    return theMethod;
}

- (void)setMethod: (SEL)aMethod
{
    theMethod = aMethod;
}

- (NSString *)name
{
    return theName;
}

- (void)setName: (NSString *)aName
{
    [aName retain];
    [theName release];
    aName = theName;
}

- (NSDictionary *)compareOperators
{
    return theCompareOperators;
}

- (void)setCompareOperators: (NSDictionary *)someOperators
{
    [someOperators retain];
    [theCompareOperators release];
    theCompareOperators = someOperators;
}

- (NSCell *)valueEditorCell
{
    return theValueEditorCell;
}

- (void)setValueEditorCell: (NSCell *)aCell
{
    [aCell retain];
    [theValueEditorCell release];
    theValueEditorCell = aCell;
}
@end