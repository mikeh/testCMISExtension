//
//  TestCMISNetworkIO.h
//  TestMDMForCMIS
//
//  Created by Peter Schmidt on 19/12/2012.
//  Copyright (c) 2012 Peter Schmidt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GD/GDNETiOS.h>
#import "CMISHttpRequestDelegate.h"

@interface TestCMISNetworkIO : NSObject <CMISHttpRequestDelegate, GDHttpRequestDelegate>
@property (nonatomic, strong) GDHttpRequest * httpRequest;
@end
