//
//  GDCReadStream+InputStream.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 20/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import <GD/GDFileSystem.h>

@interface GDCReadStream (InputStream)
+ (id)inputStreamWithFileAtPath:(NSString *)filePath;
@end
