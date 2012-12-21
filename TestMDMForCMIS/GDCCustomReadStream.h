//
//  GDCCustomReadStream.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 21/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import <GD/GDFileSystem.h>

@interface GDCCustomReadStream : GDCReadStream <NSStreamDelegate>
+ (id)inputStreamWithFileAtPath:(NSString *)filePath;
@end
