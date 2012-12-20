//
//  GDCWriteStream+OutputStream.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 20/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import <GD/GDFileSystem.h>

@interface GDCWriteStream (OutputStream)
+ (id)outputStreamToFileAtPath:(NSString *)filePath append:(BOOL)append;
@end
