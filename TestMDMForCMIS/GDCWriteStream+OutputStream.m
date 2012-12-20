//
//  GDCWriteStream+OutputStream.m
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 20/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import "GDCWriteStream+OutputStream.h"

@implementation GDCWriteStream (OutputStream)
+ (id)outputStreamToFileAtPath:(NSString *)filePath append:(BOOL)append
{
    NSError *error = nil;
    GDCWriteStream *writeStream = [GDFileSystem getWriteStream:filePath appendmode:append error:&error];
    if (error)
    {
        return nil;
    }
    return writeStream;
}
@end
