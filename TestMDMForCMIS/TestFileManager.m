//
//  TestFileManager.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 20/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "TestFileManager.h"

static NSString * kTMPDIRNAME = @"/tmp";

@implementation TestFileManager
+ (void)appendToFileAtPath:(NSString *)filePath data:(NSData *)data
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
    success = [GDFileSystem writeToFile:data name:filePath fromOffset:offset error:&error];
    if (!success)
    {
        NSLog(@"In APPEND: we could not append the file file %@. Error code = %d and message is %@", filePath, [error code], [error localizedDescription]);
        return;
    }

}

/*
 + (unsigned long long)fileSizeForFileAtPath:(NSString *)filePath error:(NSError * *)outError
 {
 NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:outError];
 
 if (*outError == nil) {
 return [attributes fileSize];
 }
 
 return 0LL;
 }
 */

+ (BOOL)fileStreamIsOpen:(NSStream *)stream
{
    BOOL isStreamOpen = NO;
    if (nil != stream)
    {
        isStreamOpen = YES;
    }
    return isStreamOpen;
}



+ (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)outError
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



+ (BOOL)createFileAtPath:(NSString *)filePath contents:(NSData *)data error:(NSError **)error
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

+ (BOOL)removeItemAtPath:(NSString *)filePath error:(NSError **)error
{
    BOOL isOk = [GDFileSystem removeItemAtPath:filePath error:error];
    if (!isOk)
    {
        NSLog(@"error removing file %@ with error code %d and message %@", filePath, [*error code], [*error localizedDescription]);
    }
    return isOk;
}

+ (NSString *)internalFilePathFromName:(NSString *)fileName
{
    NSString *tmpDirectory = [self temporaryDirectory];
    if (tmpDirectory)
    {
        return [NSString stringWithFormat:@"%@/%@", tmpDirectory, fileName];
    }
    else
    {
        NSLog(@"Couldn't access the temporary direcory.");
        return nil;
    }
}


+ (NSString *)temporaryDirectory
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

+ (BOOL)fileExistsAtPath:(NSString *)path
{
    BOOL isDir;
    return [GDFileSystem fileExistsAtPath:path isDirectory:&isDir];
}

+ (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory
{
    BOOL isDir;
    BOOL pathExists = [GDFileSystem fileExistsAtPath:path isDirectory:&isDir];
    return pathExists;
}

+ (BOOL)createDirectoryAtPath:(NSString *)path
  withIntermediateDirectories:(BOOL)createIntermediates
                   attributes:(NSDictionary *)attributes
                        error:(NSError **)error
{
    return [GDFileSystem createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

#pragma the following are not yet required in CMIS lib.




+ (BOOL)copyItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error
{
    return YES;
}

+ (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error
{
    return YES;
}

+ (NSArray *)contentsOfDirectoryAtPath:(NSString *)directoryPath error:(NSError **)error
{
    return nil;
}

+ (void)enumerateThroughDirectory:(NSString *)directory includingSubDirectories:(BOOL)includeSubDirectories error:(NSError **)error withBlock:(void (^)(NSString *fullFilePath))block{}

+ (NSData *)dataWithContentsOfURL:(NSURL *)url
{
    return nil;
}

+ (NSString *)homeDirectory
{
    return nil;
}

+ (NSString *)documentsDirectory
{
    return nil;
}

@end
