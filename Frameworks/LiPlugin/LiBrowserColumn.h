//
//  LiBrowserColumn.h
//  Liaison
//
//  Created by Brian Cully on Thu May 15 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiBrowserColumn : NSObject
{
    id theIdentifier;

    NSString *theColumnName;
    NSCell *theCell;
    NSNumber *theWidth;
    SEL theGetMethod;
    SEL theSetMethod;
    SEL theCompareMethod;
    BOOL theColumnIsEditable;
    BOOL theColumnIsResizable;
    BOOL theColumnShowsHeader;
}

- (id)objectForRecord: (id)aRecord;
- (void)setObject: (id)anObject forRecord: (id)aRecord;
@property (getter=resizable,setter=setResizable:) BOOL theColumnIsResizable;
@property (getter=setMethod,setter=setSetMethod:) SEL theSetMethod;
@property (retain,getter=name) NSString *theColumnName;
@property (getter=compareMethod,setter=setCompareMethod:) SEL theCompareMethod;
@property (getter=showsHeader,setter=setShowsHeader:) BOOL theColumnShowsHeader;
@property (retain,getter=identifier) id theIdentifier;
@property (retain,getter=width) NSNumber *theWidth;
@property (getter=editable,setter=setEditable:) BOOL theColumnIsEditable;
@property (getter=getMethod,setter=setGetMethod:) SEL theGetMethod;
@property (retain,getter=cell) NSCell *theCell;
@end

@interface LiBrowserColumn (Accessors)
- (id)identifier;
- (void)setIdentifier: (id)anIdentifier;
- (NSString *)name;
- (void)setName: (NSString *)aName;
- (BOOL)editable;
- (void)setEditable: (BOOL)editable;
- (BOOL)resizable;
- (void)setResizable: (BOOL)resizable;
- (BOOL)showsHeader;
- (void)setShowsHeader: (BOOL)showHeader;
- (NSCell *)cell;
- (void)setCell: (NSCell *)aCell;
- (SEL)getMethod;
- (void)setGetMethod: (SEL)aSelector;
- (SEL)setMethod;
- (void)setSetMethod: (SEL)aSelector;
- (SEL)compareMethod;
- (void)setCompareMethod: (SEL)aSelector;
- (NSNumber *)width;
- (void)setWidth: (NSNumber *)aWidth;
@end
