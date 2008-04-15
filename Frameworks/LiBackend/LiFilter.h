//
//  LiFilter.h
//  LiFrameworks
//
//  Created by Brian Cully on Sat Aug 23 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiFilter : NSObject
{
    NSString *theAttribute;
    NSString *theCompareSelector;
    id theValue;
}
+ (LiFilter *)filterWithAttribute: (NSString *)anAttribute
                  compareSelector: (SEL)aSelector
                            value: (id)aValue;

- (id)initWithAttribute: (NSString *)anAttribute
        compareSelector: (SEL)aSelector
                  value: (id)aValue;
@property (retain,getter=attribute) NSString *theAttribute;
@property (retain,getter=value) id theValue;
@property (retain) NSString *theCompareSelector;
@end

@interface LiFilter (Accessors)
- (NSString *)attribute;
- (void)setAttribute: (NSString *)anAttribute;
- (SEL)compareSelector;
- (void)setCompareSelector: (SEL)aSelector;
- (id)value;
- (void)setValue: (id)aValue;
@end

@interface LiFilter (CommonAccessors)
- (NSString *)description;
@end