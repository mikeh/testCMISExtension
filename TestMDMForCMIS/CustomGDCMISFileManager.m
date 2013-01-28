/*
 ******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *****************************************************************************
 */

#import "CustomGDCMISFileManager.h"
#import "CMISBase64Encoder.h"
static NSString * kTMPDIRNAME = @"/tmp";

@implementation CustomGDCMISFileManager
- (void)encodeContentFromInputStream:(GDCReadStream *)inputStream andAppendToFile:(NSString *)filePath
{
    if (![inputStream hasBytesAvailable])
    {
        NSLog(@"We seem to have an empty stream");
        return;
    }
    while ([inputStream hasBytesAvailable])
    {
        NSUInteger bufferSize = 524288;
        uint8_t buffer[bufferSize];
        NSUInteger readBytes = [inputStream read:buffer maxLength:bufferSize];
        if (0 < readBytes)
        {
            NSMutableData *bytesRead = [NSMutableData data];
            [bytesRead appendBytes:(const void *)buffer length:readBytes];
            NSData *encodedBytes = [CMISBase64Encoder dataByEncodingText:bytesRead];
            [self appendToFileAtPath:filePath data:encodedBytes];
        }
    }
    
}

- (GDCReadStream *)inputStreamWithFileAtPath:(NSString *)filePath
{
    NSError *error = nil;
    GDCReadStream *inputStream = [GDFileSystem getReadStream:filePath error:&error];
    if (error)
    {
        NSLog(@"Error creating input stream with code %d and message %@", [error code], [error localizedDescription]);
    }
    return inputStream;
}

- (void)appendToFileAtPath:(NSString *)filePath data:(NSData *)data
{
    GDFileStat stats;
    NSError *error = nil;
    BOOL success = [GDFileSystem getFileStat:filePath to:&stats error:&error];
    if (!success)
    {
        NSLog(@"In APPEND: we could not get the file stats for file %@. Error code = %d and message is %@", filePath, [error code], [error localizedDescription]);
        return;
    }
    NSInteger offset = stats.fileLen;
    
    /*
     GDCWriteStream *writeStream = [GDFileSystem getWriteStream:filePath appendmode:YES error:&error];
     if (!writeStream)
     {
     NSLog(@"couldn't create a write stream");
     return;
     }
     if (![writeStream hasSpaceAvailable])
     {
     NSLog(@"no space available in write stream");
     return;
     }
     
     NSUInteger bufferSize = [data length];
     uint8_t buffer[bufferSize];
     [data getBytes:buffer length:bufferSize];
     NSUInteger byteswritten = [writeStream write:(const uint8_t *)(&buffer) maxLength:bufferSize];
     if (byteswritten != -1)
     {
     NSLog(@"we wrote %d bytes", byteswritten);
     NSLog(@"We succeeded in calling appendToFilePath and added %d data to the end of the file from offset %d", [data length], offset);
     }
     else
     {
     NSLog(@"somehow we failed to write to the file");
     }
     */
    
    NSLog(@"the offset says we have %d bytes. The actual data length is %d", offset, [data length]);
    success = [GDFileSystem writeToFile:data name:filePath fromOffset:offset error:&error];
    if (!success)
    {
        NSLog(@"In APPEND: we could not append the file file %@. Error code = %d and message is %@", filePath, [error code], [error localizedDescription]);
        return;
    }
    
}


- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)outError
{
    NSMutableDictionary *fileAttributes = [NSMutableDictionary dictionary];
    GDFileStat myStat;
    BOOL success = [GDFileSystem getFileStat:path to:&myStat error:outError];
    unsigned long long fileSize = 0;
    if (success)
    {
        fileSize = myStat.fileLen;
    }
    else
    {
        NSLog(@"we have an error getting the file stats for file %@ with error code %d and message %@", path, [*outError code], [*outError localizedDescription]);
    }
    [fileAttributes setObject:[NSNumber numberWithUnsignedLongLong:fileSize] forKey:NSFileSize];
    return fileAttributes;
}



- (BOOL)createFileAtPath:(NSString *)filePath contents:(NSData *)data error:(NSError **)error
{
    NSString *dataToBeWritten = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Trying to set up the file at location %@ with content %@", filePath, dataToBeWritten);
    BOOL isOk = [GDFileSystem writeToFile:data name:filePath error:error];
    if (!isOk)
    {
        NSLog(@"error creating file %@ with content. Error code is %d and message is %@", filePath, [*error code], [*error localizedDescription]);
    }
    else
    {
        NSLog(@"We created a a new file");
    }
    return isOk;
}

- (BOOL)removeItemAtPath:(NSString *)filePath error:(NSError **)error
{
    BOOL isOk = [GDFileSystem removeItemAtPath:filePath error:error];
    if (!isOk)
    {
        NSLog(@"error removing file %@ with error code %d and message %@", filePath, [*error code], [*error localizedDescription]);
    }
    return isOk;
}

- (NSString *)internalFilePathFromName:(NSString *)fileName
{
    NSString *tmpDirectory = [self temporaryDirectory];
    if (tmpDirectory)
    {
        NSLog(@"Temporary file name created: %@", [NSString stringWithFormat:@"%@/%@", tmpDirectory, fileName]);
        return [NSString stringWithFormat:@"%@/%@", tmpDirectory, fileName];
    }
    else
    {
        NSLog(@"Couldn't access the temporary direcory.");
        return nil;
    }
}


- (NSString *)temporaryDirectory
{
    BOOL isDir;
    BOOL tmpExists = [GDFileSystem fileExistsAtPath:kTMPDIRNAME isDirectory:&isDir];
    if (!tmpExists || !isDir)
    {
        NSError *error = nil;
        BOOL success = [GDFileSystem createDirectoryAtPath:kTMPDIRNAME withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success)
        {
            NSLog(@"Couldn't create the temporary directory. The error code is %d and error message is %@",[error code], [error localizedDescription]);
            return nil;
        }
        else
        {
            NSLog(@"succeeded in creating tmp directory");
        }
    }
    return kTMPDIRNAME;
}

@end
