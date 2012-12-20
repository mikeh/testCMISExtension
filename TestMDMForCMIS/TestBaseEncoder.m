//
//  TestBaseEncoder.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 20/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "TestBaseEncoder.h"
#import "CMISBase64Encoder.h"
#import "TestFileManager.h"
#import <GD/GDFileSystem.h>

@implementation TestBaseEncoder

+ (NSString *)encodeContentFromInputStream:(GDCReadStream *)inputStream
{
    NSMutableString *result = [[NSMutableString alloc] init];
    while ([inputStream hasBytesAvailable])
    {
        @autoreleasepool
        {
            const NSUInteger bufferSize = 32768;
            uint8_t buffer[bufferSize];
            NSInteger bytesRead = [inputStream read:buffer maxLength:bufferSize];
            NSData *readData = [NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO];
            [result appendString:[CMISBase64Encoder stringByEncodingText:readData]];
        }
        
    }
    return result;
}

+ (void)encodeContentFromInputStream:(GDCReadStream *)inputStream andAppendToFile:(NSString *)destinationFilePath
{
    unsigned long long currentOffset = 0ULL;
    while ([inputStream hasBytesAvailable])
    {
        @autoreleasepool
        {
            const NSUInteger bufferSize = 32768;
            uint8_t buffer[bufferSize];
            NSInteger bytesRead = [inputStream read:buffer maxLength:bufferSize];
            NSData *readData = [NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO];
            [TestFileManager appendToFileAtPath:destinationFilePath data:readData];
            currentOffset += bytesRead;
        }
        
    }
    
}

+ (NSString *)encodeContentOfFile:(NSString *)sourceFilePath
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSError *error = nil;
    GDCReadStream *readStream = [GDFileSystem getReadStream:sourceFilePath error:&error];
    if (nil == readStream)
    {
        NSLog(@"An error occurred opening file  %@ in encodeContentOfFile. Error code %d, error message %@", sourceFilePath, [error code], [error localizedDescription]);
        return nil;
    }
    while ([readStream hasBytesAvailable])
    {
        @autoreleasepool
        {
            const NSUInteger bufferSize = 32768;
            uint8_t buffer[bufferSize];
            NSInteger bytesRead = [readStream read:buffer maxLength:bufferSize];
            NSData *readData = [NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO];
            [result appendString:[CMISBase64Encoder stringByEncodingText:readData]];
        }
    
    }
    [readStream close];
    return result;
    
}

+ (void)encodeContentOfFile:(NSString *)sourceFilePath andAppendToFile:(NSString *)destinationFilePath
{
    NSError *error = nil;
    GDCReadStream *readStream = [GDFileSystem getReadStream:sourceFilePath error:&error];
    if (nil == readStream)
    {
        NSLog(@"An error occurred opening file  %@ in encodeContentOfFile. Error code %d, error message %@", sourceFilePath, [error code], [error localizedDescription]);
        return;
    }
    unsigned long long currentOffset = 0ULL;
    while ([readStream hasBytesAvailable])
    {
        @autoreleasepool
        {
            const NSUInteger bufferSize = 32768;
            uint8_t buffer[bufferSize];
            NSInteger bytesRead = [readStream read:buffer maxLength:bufferSize];
            NSData *readData = [NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO];
            [TestFileManager appendToFileAtPath:destinationFilePath data:readData];
            currentOffset += bytesRead;
        }
        
    }
    [readStream close];
}
@end
