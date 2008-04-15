//
//  LiDataTranslator.h
//  Liaison
//
//  Created by Brian Cully on Thu Sep 25 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#define LiPlainEncoding 0x10101010

#import <Foundation/Foundation.h>

@interface LiDataTranslator : NSObject
+ (LiDataTranslator *)sharedTranslator;
- (NSData *)decodeData: (NSData *)someData;
- (NSData *)encodeData: (NSData *)someData;
@end

@interface NSData (LiDataTranslator)
- (NSData *)decodedData;
- (NSData *)encodedData;
@end

@interface NSDictionary (LiDataTranslator)
+ (NSDictionary *)dictionaryWithEncodedData: (NSData *)someData;
- (NSData *)encodedData;
@end