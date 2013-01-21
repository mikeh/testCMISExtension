//
//  GDHttpUtilWithSockets.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 21/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GD/GDFileSystem.h>
#import <GD/GDNETiOS.h>
#import "CMISHttpInvokerDelegate.h"

@interface GDHttpUtilWithSockets : NSObject <CMISHttpInvokerDelegate, GDSocketDelegate>
@property (nonatomic, strong) GDSocket *socket;

- (id)initWithURLString:(NSString *)urlString port:(NSUInteger)port isSSL:(BOOL)isSSL;
- (id)initWithURLString:(NSString *)urlString;
- (void)cancel;
@end
