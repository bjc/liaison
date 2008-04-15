//
//  LiFilterDescription.h
//  LiFrameworks
//
//  Created by Brian Cully on Sat Aug 23 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiFilterDescription : NSObject
{
    NSCell *theValueEditorCell;
    NSDictionary *theCompareOperators;
    NSString *theName;
    SEL theMethod;
}
+ (id)descriptionForMethod: (SEL)aMethod
                      name: (NSString *)aName
          compareOperators: (NSDictionary *)someOperators
           valueEditorCell: (NSCell *)aCell;

- (id)initWithMethod: (SEL)aMethod
                name: (NSString *)aName
    compareOperators: (NSDictionary *)someOperators
     valueEditorCell: (NSCell *)aCell;
@property (getter=method,setter=setMethod:) SEL theMethod;
@property (retain,getter=name) NSString *theName;
@property (retain,getter=valueEditorCell) NSCell *theValueEditorCell;
@property (retain,getter=compareOperators) NSDictionary *theCompareOperators;
@end

@interface LiFilterDescription (Accessors)
- (SEL)method;
- (void)setMethod: (SEL)aMethod;
- (NSString *)name;
- (void)setName: (NSString *)aName;
- (NSDictionary *)compareOperators;
- (void)setCompareOperators: (NSDictionary *)someOperators;
- (NSCell *)valueEditorCell;
- (void)setValueEditorCell: (NSCell *)aCell;
@end
