//
//  LiDataTranslator.m
//  Liaison
//
//  Created by Brian Cully on Thu Sep 25 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiDataTranslator.h"

@implementation LiDataTranslator
static LiDataTranslator *sharedTranslator = nil;
+ (LiDataTranslator *)sharedTranslator
{
    if (sharedTranslator == nil)
        sharedTranslator = [[self alloc] init];
    return sharedTranslator;
}

- (NSData *)decodeData: (NSData *)someData
{
    NSData *myData;
    NSRange headerRange;
    unsigned long encoding, length;
    unsigned dataLen;

    myData = nil;
    headerRange.location = 0;
    headerRange.length = sizeof(encoding) + sizeof(length);
    dataLen = [someData length];
    if (dataLen > headerRange.length) {

        dataLen -= headerRange.length;
        [someData getBytes: &encoding range: NSMakeRange(0, sizeof(encoding))];
        [someData getBytes: &length range: NSMakeRange(sizeof(encoding), sizeof(length))];
        encoding = ntohl(encoding);
        length = ntohl(length);

        if (dataLen >= length) {
            myData = [someData subdataWithRange: NSMakeRange(headerRange.length, length)];
        }
    }
    
    return myData;
}

- (NSData *)encodeData: (NSData *)someData
{
    NSMutableData *myData;

    myData = nil;
    if (someData != nil) {
        unsigned long encoding, length;

        myData = [NSMutableData data];
        encoding = htonl(LiPlainEncoding);
        length = htonl([someData length]);

        [myData appendBytes: &encoding length: sizeof(encoding)];
        [myData appendBytes: &length length: sizeof(length)];
        [myData appendData: someData];
    }
    return myData;
}
@end

@implementation NSData (LiDataTranslator)
- (NSData *)decodedData
{
    return [[LiDataTranslator sharedTranslator] decodeData: self];
}

- (NSData *)encodedData
{
    return [[LiDataTranslator sharedTranslator] encodeData: self];
}
@end

@implementation NSDictionary (LiDataTranslator)
+ (NSDictionary *)dictionaryWithEncodedData: (NSData *)someData
{
    NSData *myData;
    NSDictionary *msg;

    msg = nil;
    myData = [someData decodedData];
    if (myData != nil) {
        NSString *errorString;

        errorString = nil;
        msg = [NSPropertyListSerialization propertyListFromData: myData
                                               mutabilityOption: NSPropertyListImmutable
                                                         format: NULL
                                               errorDescription: &errorString];
        if (errorString != nil || [msg isKindOfClass: [NSDictionary class]] == NO) {
            [msg release];
            [errorString release];
            return nil;
        }
    }
    return msg;
}

- (NSData *)encodedData
{
    NSData *myData;
    NSString *errorString;

    errorString = nil;
    myData = [NSPropertyListSerialization dataFromPropertyList: self
                                                        format: NSPropertyListBinaryFormat_v1_0
                                              errorDescription: &errorString];
    if (errorString != nil) {
        [LiLog logAsError: @"Couldn't serialize dictionary: %@.", errorString];
        [errorString release];
        return nil;
    }
    return [myData encodedData];
}
@end