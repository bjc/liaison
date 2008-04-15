//
//  FileSizeFormatter.m
//  Liaison
//
//  Created by Brian Cully on Fri May 09 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "FileSizeFormatter.h"

@implementation FileSizeFormatter
- (NSString *)stringForObjectValue: (id)anObject
{
    if ([anObject isKindOfClass: [NSNumber class]]) {
        NSString *suffix;
        int shownSize;
        unsigned long size;

        size = [anObject unsignedLongValue];
        if (size > 1024 * 1024 * 1024) {
            shownSize = size / 1024 / 1024 / 1024;
            suffix = @" G";
        } else if (size > 1024 * 1024) {
            shownSize = size / 1024 / 1024;
            suffix = @" M";
        } else if (size > 1024) {
            shownSize = size / 1024;
            suffix = @" K";
        } else {
            shownSize = size;
            suffix = @" B";
        }

        return [NSString stringWithFormat: @"%ld%@", shownSize, suffix];
    }

    return [super stringForObjectValue: anObject];
}

- (BOOL)getObjectValue: (id *)anObject
             forString: (NSString *)string
      errorDescription: (NSString **)error
{
    *anObject = string;
    return YES;
}
@end
