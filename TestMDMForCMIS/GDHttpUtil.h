//
//  GDHttpUtil.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 09/01/2013.
//  Copyright (c) 2013 Peter Schmidt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GD/GDNETiOS.h>
#import "CMISHttpInvokerDelegate.h"

@interface GDHttpUtil : NSObject <CMISHttpInvokerDelegate, GDHttpRequestDelegate>
@property (nonatomic, strong) GDHttpRequest *httpRequest;
- (void)cancel;
@end
