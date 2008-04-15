//
//  LiLog.m
//  Liaison
//
//  Created by Brian Cully on Tue May 20 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiLog.h"

@implementation LiLog
static int debugIndentLevel = 0;

+ (void)alertDidEnd: (NSWindow *)sheet
         returnCode: (int)returnCode
        contextInfo: (void *)contextInfo
{
    [sheet close];
    
    return;
}

+ (void)alertWithHeader: (NSString *)aHeader
               contents: (NSString *)someContents
              forWindow: (NSWindow *)aWindow
{
    if (aWindow != nil)
        NSBeginAlertSheet(aHeader, @"Okay", nil, nil, aWindow, self,
                          @selector(alertDidEnd:returnCode:contextInfo:),
                          @selector(alertDidEnd:returnCode:contextInfo:),
                          nil, someContents);
    else
        NSRunAlertPanel(aHeader, someContents, @"Okay", nil, nil);
}

+ (void)alertWithHeader: (NSString *)aHeader
               contents: (NSString *)someContents
{
    [self alertWithHeader: aHeader contents: someContents forWindow: [NSApp keyWindow]];
}

+ (void)logAsDebug: (NSString *)format, ...
{
#define DEBUG 1
#if DEBUG
    va_list args;

    va_start(args, format);
    NSLogv([[@"DEBUG: " stringByAppendingString: [self debugIndentString]] stringByAppendingString: format], args);
    va_end(args);
#endif
}

+ (void)logAsInfo: (NSString *)format, ...
{
    va_list args;

    va_start(args, format);
    NSLogv([@"INFO: " stringByAppendingString: format], args);
    va_end(args);
}

+ (void)logAsWarning: (NSString *)format, ...
{
    va_list args;

    va_start(args, format);
    NSLogv([@"WARNING: " stringByAppendingString: format], args);
    va_end(args);
}

+ (void)logAsError: (NSString *)format, ...
{
    va_list args;

    va_start(args, format);
    NSLogv([@"ERROR: " stringByAppendingString: format], args);
    va_end(args);
}

+ (id)indentDebugLog
{
    debugIndentLevel++;
    return self;
}

+ (id)unindentDebugLog
{
    if (debugIndentLevel > 0)
        debugIndentLevel--;
    return self;
}

+ (NSString *)debugIndentString
{
    NSMutableString *indentString;
    int i;

    indentString = [NSMutableString string];
    for (i = 0; i < debugIndentLevel; i++)
        [indentString appendString: @"\t"];
    return indentString;
}
@end
