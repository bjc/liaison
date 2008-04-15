#import "HFSCodeFormatter.h"

@implementation HFSCodeFormatter
- (NSString *)stringForObjectValue: (id)anObject
{
    unsigned long longValue;
    char a, b, c, d;
    
    if ([anObject isKindOfClass: [NSNumber class]])
        longValue = [anObject unsignedLongValue];
    else
        longValue = 0;

    a = (longValue >> 24) & 0xff;
    b = (longValue >> 16) & 0xff;
    c = (longValue >> 8) & 0xff;
    d = longValue & 0xff;

    return [NSString stringWithFormat: @"%c%c%c%c", a, b, c, d];
}

- (BOOL)getObjectValue: (id *)anObject
             forString: (NSString *)string
      errorDescription: (NSString **)error
{
    unsigned long objectValue;
    unsigned int i, bitNo;
    
    bitNo = 24;
    objectValue = 0;
    for (i = 0; i < [string length] && i < 4; i++) {
        objectValue += ([string characterAtIndex: i] & 0xff) << bitNo;
        bitNo -= 8;
    }
    *anObject = [NSNumber numberWithUnsignedLong: objectValue];

    return YES;
}

- (BOOL)isPartialStringValid: (NSString *)partialString
            newEditingString: (NSString **)newString
            errorDescription: (NSString **)error
{
    return [partialString length] <= 4;
}
@end
