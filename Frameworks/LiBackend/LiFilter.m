//
//  LiFilter.m
//  LiFrameworks
//
//  Created by Brian Cully on Sat Aug 23 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiFilter.h"

@implementation LiFilter
+ (LiFilter *)filterWithAttribute: (NSString *)anAttribute
                  compareSelector: (SEL)aSelector
                            value: (id)aValue
{
    LiFilter *tmpFilter;

    tmpFilter = [[self alloc] initWithAttribute: anAttribute
                                compareSelector: aSelector
                                          value: aValue];
    return [tmpFilter autorelease];
}

- (id)init
{
    NSException *exception;

    exception = [NSException exceptionWithName: @"LiNoInitException"
                                        reason: @"[LiFilter init] not supported"
                                      userInfo: nil];
    [exception raise];
    
    return nil;
}

- (void)dealloc
{
    [self setAttribute: nil];
    [self setCompareSelector: nil];
    [self setValue: nil];

    [super dealloc];
}

- (id)initWithAttribute: (NSString *)anAttribute
        compareSelector: (SEL)aSelector
                  value: (id)aValue
{
    self = [super init];

    [self setAttribute: anAttribute];
    [self setCompareSelector: aSelector];
    [self setValue: aValue];

    return self;
}
@synthesize theCompareSelector;
@synthesize theAttribute;
@synthesize theValue;
@end

@implementation LiFilter (Accessors)
- (NSString *)attribute
{
    return theAttribute;
}

- (void)setAttribute: (NSString *)anAttribute
{
    [anAttribute retain];
    [theAttribute release];
    theAttribute = anAttribute;
}

- (SEL)compareSelector
{
    return NSSelectorFromString(theCompareSelector);
}

- (void)setCompareSelector: (SEL)aSelector
{
    [theCompareSelector release];
    theCompareSelector = [NSStringFromSelector(aSelector) retain];
}

- (id)value
{
    return theValue;
}

- (void)setValue: (id)aValue
{
    [aValue retain];
    [theValue release];
    theValue = aValue;
}
@end

@implementation LiFilter (CommonAccessors)
- (NSString *)description
{
    NSString *desc;
    
    desc = [NSString stringWithFormat: @"{\n\tattribute: %@\n\tselector: %@\n\tvalue: %@\n}",
        theAttribute, theCompareSelector, [theValue description]];
    return desc;
}
@end