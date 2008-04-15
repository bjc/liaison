//
//  LiLog.h
//  Liaison
//
//  Created by Brian Cully on Tue May 20 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiLog : NSObject
+ (void)alertWithHeader: (NSString *)aHeader
               contents: (NSString *)someContents;

+ (void)logAsDebug: (NSString *)format, ...;
+ (void)logAsInfo: (NSString *)format, ...;
+ (void)logAsWarning: (NSString *)format, ...;
+ (void)logAsError: (NSString *)format, ...;

+ (id)indentDebugLog;
+ (id)unindentDebugLog;
+ (NSString *)debugIndentString;
@end
