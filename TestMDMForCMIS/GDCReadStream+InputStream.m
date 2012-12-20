//
//  GDCReadStream+InputStream.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 20/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "GDCReadStream+InputStream.h"

@implementation GDCReadStream (InputStream)
+ (id)inputStreamWithFileAtPath:(NSString *)filePath
{
    NSError *error = nil;
    GDCReadStream *readStream = [GDFileSystem getReadStream:filePath error:&error];
    if (error)
    {
        return nil;
    }    
    return readStream;
}
@end
