//
//  NaturalDateFormatter.m
//  BuiltInFunctions
//
//  Created by Brian Cully on Sun Aug 31 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "NaturalDateFormatter.h"

#import "LiBuiltInFunctions.h"

static NSString *
myLocalizedString(NSString *aString)
{
    return NSLocalizedStringFromTableInBundle(aString, @"BuiltInFunctions",
                                              [LiBuiltInFunctions bundle], @"");
}

@implementation NaturalDateFormatter
- (id)initWithNaturalLanguage: (BOOL)flag
{
    NSString *format;

    format = [[NSUserDefaults standardUserDefaults] objectForKey: NSShortDateFormatString];

    self = [super initWithDateFormat: format allowNaturalLanguage: flag];
    return self;
}

- (NSString *)stringForObjectValue: (id)anObject
{
    NSString *stringValue;

    if ([anObject isKindOfClass: [NSDate class]]) {
        NSCalendarDate *testDate;
        int todayNum, myNum;

        testDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:
            [(NSDate *)anObject timeIntervalSinceReferenceDate]];
        myNum = [[NSCalendarDate calendarDate] dayOfCommonEra];
        todayNum = [testDate dayOfCommonEra];
        if (myNum == todayNum)
            stringValue = myLocalizedString(@"Today");
        else if (todayNum == (myNum - 1))
            stringValue = myLocalizedString(@"Yesterday");
        else if (todayNum == (myNum + 1))
            stringValue = myLocalizedString(@"Tomorrow");
        else {
            stringValue = [testDate descriptionWithCalendarFormat:
                [self dateFormat]];
        }
    } else
        stringValue = [super stringForObjectValue: anObject];

    return stringValue;
}
@end
